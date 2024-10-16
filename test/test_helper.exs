ExUnit.start()

defmodule Fixture do
  require OffBroadwayAmqp10.Amqp10.Client.Impl

  def configuration(opts \\ []) do
    connection_opts = [
      hostname: "localhost",
      port: 5671,
      sasl: [
        mechanism: :plain,
        username: "foo",
        password: "bar"
      ]
    ]

    session_opts = [
      name: "some_session_name",
      snd_settle_mode: :mixed,
      rcv_settle_mode: :second
    ]

    Keyword.merge(
      [
        queue: "some_queue",
        connection: connection_opts,
        session: session_opts,
        client_module: FakeAmqpClient
      ],
      opts
    )
  end

  def build_amqp_state do
    OffBroadwayAmqp10.Amqp10.State.new(configuration())
  end

  def build_producer_state(opts \\ []) do
    OffBroadwayAmqp10.Producer.State.new(configuration(opts))
  end

  def raw_msg(value \\ "Itachi") do
    raw_msg = :amqp10_msg.new("delivery_tag", value)
    raw_msg = :amqp10_msg.set_headers(%{:durable => false, priority: 4}, raw_msg)

    raw_msg =
      :amqp10_msg.set_properties(
        %{
          absolute_expiry_time: 1_658_155_022_583,
          creation_time: 1_656_945_422_583,
          message_id: "00000000000000000000000000000000"
        },
        raw_msg
      )

    raw_msg =
      :amqp10_msg.set_application_properties(
        %{"bar" => "baz", "foo" => "bar"},
        raw_msg
      )

    :amqp10_msg.set_message_annotations(
      %{
        "x-opt-enqueued-time" => 1_656_945_422_583,
        "x-opt-sequence-number" => 6068
      },
      raw_msg
    )
  end

  def raw_msg_amqp10_value do
    value = :amqp10_client_types.utf8("Itachi")
    record = OffBroadwayAmqp10.Amqp10.Client.Impl.amqp_value(content: value)
    raw_msg(record)
  end

  def raw_msg_amqp10_sequence do
    values = [
      :amqp10_client_types.utf8("Itachi"),
      :amqp10_client_types.utf8("Shisui")
    ]

    records = [OffBroadwayAmqp10.Amqp10.Client.Impl.amqp_sequence(content: values)]
    raw_msg(records)
  end
end

defmodule FakeAmqpClient do
  @behaviour OffBroadwayAmqp10.Amqp10.Client

  alias OffBroadwayAmqp10.Amqp10.State

  @impl true
  defdelegate body(raw_msg), to: OffBroadwayAmqp10.Amqp10.Client.Impl

  @impl true
  defdelegate headers(raw_msg), to: OffBroadwayAmqp10.Amqp10.Client.Impl

  @impl true
  defdelegate properties(raw_msg), to: OffBroadwayAmqp10.Amqp10.Client.Impl

  @impl true
  defdelegate application_properties(raw_msg), to: OffBroadwayAmqp10.Amqp10.Client.Impl

  @impl true
  defdelegate annotations(raw_msg), to: OffBroadwayAmqp10.Amqp10.Client.Impl

  @impl true
  def open_connection(%State{} = state) do
    send(self(), {__MODULE__, :open_connection_called, [state]})

    {:ok, self()}
  end

  @impl true
  def begin_session(%State{} = state) do
    send(self(), {__MODULE__, :begin_session_called, [state]})

    {:ok, self()}
  end

  @impl true
  def attach(%State{} = state) do
    send(self(), {__MODULE__, :attach_called, [state]})

    {:ok, self()}
  end

  @impl true
  def flow_link_credit(%State{} = state, demand) do
    send(self(), {__MODULE__, :flow_link_credit_called, [state, demand]})

    :ok
  end

  @impl true
  def accept_msg(%State{} = state, raw_message) do
    send(self(), {__MODULE__, :accept_msg_called, [state, raw_message]})

    :ok
  end
end

defmodule RealisticFakeAmqpClient do
  @behaviour OffBroadwayAmqp10.Amqp10.Client

  use GenServer

  alias OffBroadwayAmqp10.Amqp10.State

  @impl true
  defdelegate body(raw_msg), to: OffBroadwayAmqp10.Amqp10.Client.Impl

  @impl true
  defdelegate headers(raw_msg), to: OffBroadwayAmqp10.Amqp10.Client.Impl

  @impl true
  defdelegate properties(raw_msg), to: OffBroadwayAmqp10.Amqp10.Client.Impl

  @impl true
  defdelegate application_properties(raw_msg), to: OffBroadwayAmqp10.Amqp10.Client.Impl

  @impl true
  defdelegate annotations(raw_msg), to: OffBroadwayAmqp10.Amqp10.Client.Impl

  @impl true
  def open_connection(%State{} = state) do
    GenServer.call(__MODULE__, {:open_connection, state, self()})
  end

  @impl true
  def begin_session(%State{} = state) do
    GenServer.call(__MODULE__, {:begin_session, state, self()})
  end

  @impl true
  def attach(%State{} = state) do
    GenServer.call(__MODULE__, {:attach, state, self()})
  end

  @impl true
  def flow_link_credit(%State{} = state, demand) do
    GenServer.call(__MODULE__, {:flow_link_credit, demand, state, self()})
  end

  @impl true
  def accept_msg(%State{} = state, msg) do
    GenServer.call(__MODULE__, {:accept_msg, msg, state, self()})
  end

  def start_link(test_pid) do
    {:ok, _} = GenServer.start_link(__MODULE__, [test_pid: test_pid], name: __MODULE__)
  end

  @impl true
  def init(test_pid: test_pid) do
    {:ok, %{test_pid: test_pid, producer_pid: nil}}
  end

  def send_connection_opened do
    GenServer.call(__MODULE__, :send_connection_opened)
  end

  def send_session_begun do
    GenServer.call(__MODULE__, :send_session_begun)
  end

  def send_attached do
    GenServer.call(__MODULE__, :send_attached)
  end

  def send_msg(payload) do
    GenServer.call(__MODULE__, {:send_msg, payload})
  end

  @impl true
  def handle_call(:send_connection_opened, _, state) do
    send(state.producer_pid, {:amqp10_event, {:connection, self(), :opened}})

    {:reply, :ok, state}
  end

  def handle_call(:send_session_begun, _, state) do
    send(state.producer_pid, {:amqp10_event, {:session, self(), :begun}})

    {:reply, :ok, state}
  end

  def handle_call(:send_attached, _, state) do
    send(
      state.producer_pid,
      {:amqp10_event, {:link, {:link_ref, :receiver, self(), 0}, :attached}}
    )

    {:reply, :ok, state}
  end

  def handle_call({:send_msg, payload}, _, state) do
    msg = :amqp10_msg.new("delivery_tag", payload)

    send(
      state.producer_pid,
      {:amqp10_msg, {:link_ref, :receiver, self(), 0}, msg}
    )

    {:reply, :ok, state}
  end

  def handle_call({:open_connection, amqp_state, producer_pid}, _, state) do
    new_state = %{state | producer_pid: producer_pid}

    send(state.test_pid, {__MODULE__, :open_connection_called, [amqp_state, state]})

    {:reply, {:ok, self()}, new_state}
  end

  def handle_call({:begin_session, amqp_state, producer_pid}, _, state) do
    new_state = %{state | producer_pid: producer_pid}

    send(state.test_pid, {__MODULE__, :begin_session_called, [amqp_state, state]})

    {:reply, {:ok, self()}, new_state}
  end

  def handle_call({:attach, amqp_state, producer_pid}, _, state) do
    new_state = %{state | producer_pid: producer_pid}

    send(state.test_pid, {__MODULE__, :attach_called, [amqp_state, state]})

    {:reply, {:ok, self()}, new_state}
  end

  def handle_call({:flow_link_credit, demand, amqp_state, producer_pid}, _, state) do
    new_state = %{state | producer_pid: producer_pid}

    send(state.test_pid, {__MODULE__, :flow_link_credit_called, [demand, amqp_state, state]})

    {:reply, :ok, new_state}
  end

  def handle_call({:accept_msg, msg, amqp_state, producer_pid}, _, state) do
    new_state = %{state | producer_pid: producer_pid}

    send(state.test_pid, {__MODULE__, :accept_msg, [msg, amqp_state, state]})

    {:reply, :ok, new_state}
  end
end
