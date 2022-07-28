defmodule OffBroadwayAmqp10.Producer.StateTest do
  use ExUnit.Case, async: true

  alias OffBroadwayAmqp10.Amqp10
  alias OffBroadwayAmqp10.Producer.State, as: SUT

  setup do
    %{state: Fixture.build_producer_state()}
  end

  describe "new" do
    test "builds initial state" do
      assert %SUT{demand: 0, amqp: %Amqp10.State{}} = SUT.new(Fixture.configuration())
    end
  end

  describe "increase_demand/2" do
    test "increases demand by arg", %{state: state} do
      state =
        state
        |> SUT.increase_demand(100)
        |> SUT.increase_demand(5)

      assert state.demand == 105
    end
  end

  describe "decrease_demand/2" do
    test "decreases demand by arg", %{state: state} do
      state =
        state
        |> SUT.increase_demand(200)
        |> SUT.decrease_demand(5)

      assert state.demand == 195
    end

    test "doesn't decrease below 0", %{state: state} do
      state =
        state
        |> SUT.increase_demand(1)
        |> SUT.decrease_demand(5)

      assert state.demand == 0
    end
  end

  describe "set_connection/2" do
    test "sets the connnection", %{state: state} do
      some_pid = self()

      assert result_state = SUT.set_connection(state, some_pid)
      assert result_state.amqp.connection == some_pid
      assert result_state.amqp.connection_status == :initialized
    end
  end

  describe "set_connection_status/2" do
    test "set connection status", %{state: state} do
      new_state = SUT.set_connection_status(state, :initialized)

      assert :initialized = new_state.amqp.connection_status
    end
  end

  describe "set_session/2" do
    test "sets the session", %{state: state} do
      some_pid = self()

      assert result_state = SUT.set_session(state, some_pid)
      assert result_state.amqp.session == some_pid
      assert result_state.amqp.session_status == :initialized
    end
  end

  describe "set_session_status/2" do
    test "set session status", %{state: state} do
      new_state = SUT.set_session_status(state, :initialized)

      assert :initialized = new_state.amqp.session_status
    end
  end

  describe "set_receiver/2" do
    test "sets the receiver", %{state: state} do
      some_pid = self()

      assert result_state = SUT.set_receiver(state, some_pid)
      assert result_state.amqp.receiver == some_pid
      assert result_state.amqp.receiver_status == :initialized
    end
  end

  describe "set_receiver_status/2" do
    test "set receiver status", %{state: state} do
      new_state = SUT.set_receiver_status(state, :initialized)

      assert :initialized = new_state.amqp.receiver_status
    end
  end

  describe "has_demand/1" do
    test "true when demand is bigger than 0", %{state: state} do
      state = SUT.increase_demand(state, 100)

      assert SUT.has_demand?(state) == true
    end

    test "false when demand is 0", %{state: state} do
      state = SUT.decrease_demand(state, 1_000)

      refute SUT.has_demand?(state)
    end
  end

  describe "credits_within_limits/1" do
    test "returns credit limit when demand is higher than credit limit", %{state: state} do
      state = %SUT{state | credit_limit: 100, demand: 200}

      assert SUT.credits_within_limits(state) == 100
    end

    test "returns demand when demand is lower than credit limit", %{state: state} do
      state = %SUT{state | credit_limit: 100, demand: 20}

      assert SUT.credits_within_limits(state) == 20
    end
  end

  describe "receiver_attached/1" do
    test "returns true when receiver is attached", %{state: state} do
      amqp =
        state.amqp
        |> Amqp10.State.set_receiver(self())
        |> Amqp10.State.set_receiver_status(:attached)

      state = %SUT{amqp: amqp}

      assert SUT.receiver_attached?(state)
    end

    test "returns false when receiver is not attached", %{state: state} do
      amqp =
        state.amqp
        |> Amqp10.State.set_receiver(self())
        |> Amqp10.State.set_receiver_status(:detached)

      state = %SUT{amqp: amqp}

      refute SUT.receiver_attached?(state)
    end

    test "returns false when receiver is not present", %{state: state} do
      amqp =
        state.amqp
        |> Amqp10.State.set_receiver(nil)
        |> Amqp10.State.set_receiver_status(:attached)

      state = %SUT{amqp: amqp}

      refute SUT.receiver_attached?(state)
    end
  end
end
