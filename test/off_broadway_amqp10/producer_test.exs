defmodule OffBroadwayAmqp10.ProducerTest do
  use ExUnit.Case, async: true

  alias OffBroadwayAmqp10.Producer.State
  alias OffBroadwayAmqp10.Amqp10
  alias OffBroadwayAmqp10.Producer, as: SUT

  setup do
    %{config: Fixture.configuration(), state: Fixture.build_producer_state()}
  end

  describe "init/1" do
    test "initiates producer state", %{config: config} do
      assert {:producer, %State{}, []} = SUT.init(config)
    end

    test "invoke open connection", %{config: config} do
      SUT.init(config)

      assert_receive :open_connection
    end
  end

  describe "handle_demand/2" do
    test "calculates demand", %{state: state} do
      assert {:noreply, [], state = %State{demand: 2}} = SUT.handle_demand(2, state)
      assert {:noreply, [], %State{demand: 6}} = SUT.handle_demand(4, state)
    end

    test "invoke maybe ask credits", %{state: state} do
      SUT.handle_demand(2, state)

      assert_receive :maybe_ask_credits
    end
  end

  describe "handle_info: maybe_ask_credit" do
    test "ask for credit when receiver is attached", %{state: state} do
      state =
        state
        |> State.increase_demand(10)
        |> State.set_receiver(self())
        |> State.set_receiver_status(:attached)

      assert {:noreply, [], %State{}} = SUT.handle_info(:maybe_ask_credits, state)
      assert_receive {FakeAmqpClient, :flow_link_credit_called, [%Amqp10.State{}, 10]}
    end

    test "does not ask for credit when receiver not attached", %{state: state} do
      state =
        state
        |> State.increase_demand(0)
        |> State.set_receiver(self())
        |> State.set_receiver_status(:detached)

      assert {:noreply, [], %State{}} = SUT.handle_info(:maybe_ask_credits, state)
      refute_receive {FakeAmqpClient, :flow_link_credit_called, _}
    end

    test "does not ask for credit when demand is 0", %{state: state} do
      state =
        state
        |> State.increase_demand(0)
        |> State.set_receiver(self())
        |> State.set_receiver_status(:attached)

      assert {:noreply, [], %State{}} = SUT.handle_info(:maybe_ask_credits, state)
      refute_receive {FakeAmqpClient, :flow_link_credit_called, _}
    end

    test "limits credit request based on transfer_limit_margin", %{state: state} do
      state =
        %State{state | credit_limit: 42}
        |> State.increase_demand(100_000)
        |> State.set_receiver(self())
        |> State.set_receiver_status(:attached)

      assert {:noreply, [], %State{}} = SUT.handle_info(:maybe_ask_credits, state)
      assert_receive {FakeAmqpClient, :flow_link_credit_called, [_, 42]}
    end
  end

  describe "handle_info: open_connection" do
    test "opens connection", %{state: state} do
      assert {:noreply, [], new_state} = SUT.handle_info(:open_connection, state)

      assert new_state.amqp.connection
      assert :initialized = new_state.amqp.connection_status
      assert_receive({FakeAmqpClient, :open_connection_called, [%Amqp10.State{}]})
    end
  end

  describe "amqp10 event: connection opened" do
    test "set the connection status to open", %{state: state} do
      assert {:noreply, [], new_state} =
               SUT.handle_info({:amqp10_event, {:connection, self(), :opened}}, state)

      assert :open = new_state.amqp.connection_status
    end

    test "invoke begin session", %{state: state} do
      SUT.handle_info({:amqp10_event, {:connection, self(), :opened}}, state)

      assert_receive :begin_session
    end
  end

  describe "handle_info: begin_session" do
    test "begins session", %{state: state} do
      state = State.set_connection(state, self())

      assert {:noreply, [], new_state} = SUT.handle_info(:begin_session, state)

      assert new_state.amqp.session
      assert :initialized = new_state.amqp.session_status
      assert_receive({FakeAmqpClient, :begin_session_called, [%Amqp10.State{}]})
    end
  end

  describe "amqp10 event: session begun" do
    test "set the session status", %{state: state} do
      assert {:noreply, [], new_state} =
               SUT.handle_info({:amqp10_event, {:session, self(), :begun}}, state)

      assert :begun = new_state.amqp.session_status
    end

    test "invoke attach receiver", %{state: state} do
      SUT.handle_info({:amqp10_event, {:session, self(), :begun}}, state)

      assert_receive :attach_receiver
    end
  end

  describe "handle_info: attach_receiver" do
    test "attaches receiver", %{state: state} do
      state =
        state
        |> State.set_connection(self())
        |> State.set_session(self())

      assert {:noreply, [], new_state} = SUT.handle_info(:attach_receiver, state)

      assert new_state.amqp.receiver
      assert :initialized = new_state.amqp.receiver_status
      assert_receive({FakeAmqpClient, :attach_called, [%Amqp10.State{}]})
    end
  end

  describe "amqp10 event: receiver attached" do
    test "set the receiver status", %{state: state} do
      assert {:noreply, [], new_state} =
               SUT.handle_info(
                 {:amqp10_event, {:link, {:link_ref, :receiver, self(), 0}, :attached}},
                 state
               )

      assert :attached = new_state.amqp.receiver_status
    end

    test "invoke maybe ask credits", %{state: state} do
      SUT.handle_info(
        {:amqp10_event, {:link, {:link_ref, :receiver, self(), 0}, :attached}},
        state
      )

      assert_receive :maybe_ask_credits
    end
  end

  describe "amqp10 event: credit exhausted" do
    test "invoke maybe ask credits", %{state: state} do
      assert {:noreply, [], new_state} =
               SUT.handle_info(
                 {:amqp10_event, {:link, {:link_ref, :receiver, self(), 0}, :credit_exhausted}},
                 state
               )

      assert state == new_state
      assert_receive :maybe_ask_credits
    end
  end

  describe "amqp10 msg" do
    setup do
      %{raw_msg: Fixture.raw_msg()}
    end

    test "returns message", %{state: state, raw_msg: raw_msg} do
      assert {:noreply, [message], %State{}} =
               SUT.handle_info({:amqp10_msg, {:link_ref, :receiver, self(), 0}, raw_msg}, state)

      assert %Broadway.Message{
               status: :ok,
               acknowledger:
                 {OffBroadwayAmqp10.Acknowledger, %OffBroadwayAmqp10.Amqp10.State{}, ^raw_msg},
               data: "Itachi",
               metadata: %{
                 annotations: %{
                   "x-opt-enqueued-time" => 1_656_945_422_583,
                   "x-opt-sequence-number" => 6068
                 },
                 application_properties: %{"bar" => "baz", "foo" => "bar"},
                 headers: %{delivery_count: 0, durable: false, first_acquirer: false, priority: 4},
                 properties: %{
                   absolute_expiry_time: 1_658_155_022_583,
                   creation_time: 1_656_945_422_583,
                   message_id: "00000000000000000000000000000000"
                 }
               }
             } = message
    end

    test "decreases demand", %{state: state, raw_msg: raw_msg} do
      state = State.increase_demand(state, 10)

      assert {:noreply, [_], %State{} = new_state} =
               SUT.handle_info({:amqp10_msg, {:link_ref, :receiver, self(), 0}, raw_msg}, state)

      assert new_state.demand == 9
    end
  end
end
