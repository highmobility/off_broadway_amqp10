defmodule OffBroadwayAmqp10.Producer do
  @moduledoc """
  An AMQP 1.0 producer for [Broadway](https://hexdocs.pm/broadway).

  ## Features
    * Automatically acknowledges/rejects messages.


  ## Options
  #{NimbleOptions.docs(OffBroadwayAmqp10.Producer.Params.__opts_schema__())}



  ## Example

      Broadway.start_link(MyBroadway,
        name: MyBroadway,
        producer: [
          module:
            {OffBroadwayAmqp10.Producer,
            queue: "my_queue",
            connection: [
              hostname: "my-service.servicebus.windows.net",
              sasl: [mechanism: :plain, username: "foo", password: "bar"],
              tls_opts: [],
              transfer_limit_margin: 100
            ],
            session: [
              name: to_string(node())
            ]},
          concurrency: 1
        ],
        processors: [
          default: [
            concurrency: 2,
          ]
        ]
      )

  ## Message

  The messages which you receive at the Broadway's processors is like:


      message = %Broadway.Message{
        data: "raw message body",
        metadata: %{
          headers: %{delivery_count: 0, durable: false, ... },
          properties: %{creation_time: 1_656_945_422_583, ...},
          application_properties: %{"foo" => "bar", ...},
          annotations: %{"x-opt-sequence-number" => 6068, .. }
        }
      }

  ## Acking

  Successful messages are acked and failed messages are rejected

  """
  use GenStage
  require Logger

  alias Broadway.Message
  alias OffBroadwayAmqp10.Producer.State

  @impl GenStage
  def handle_demand(incoming_demand, state) do
    log_event("incomming demand(#{incoming_demand})")

    new_state = State.increase_demand(state, incoming_demand)

    send(self(), :maybe_ask_credits)

    {:noreply, [], new_state}
  end

  @impl GenStage
  def init(opts) do
    state = State.new(opts)

    send(self(), :open_connection)

    {:producer, state, []}
  end

  @impl GenStage
  def handle_info(:open_connection, state) do
    log_command("open connection")

    {:ok, connection} = state.amqp.client_module.open_connection(state.amqp)

    new_state = State.set_connection(state, connection)

    {:noreply, [], new_state}
  end

  @impl GenStage
  def handle_info({:amqp10_event, {:connection, _, :opened}}, state) do
    log_event("connection opened")

    new_state = State.set_connection_status(state, :open)

    send(self(), :begin_session)

    {:noreply, [], new_state}
  end

  @impl GenStage
  def handle_info(
        {:amqp10_event, {:connection, _, {:closed, {:forced, error_message}}}},
        state
      ) do
    Logger.error("off_broadway_amqp10 connection closed forcefully, message: [#{error_message}]")

    {:stop, :connection_closed_forcefully, state}
  end

  @impl GenStage
  def handle_info(:begin_session, state) do
    log_command("begin session")

    {:ok, session} = state.amqp.client_module.begin_session(state.amqp)

    new_state = State.set_session(state, session)

    {:noreply, [], new_state}
  end

  @impl GenStage
  def handle_info({:amqp10_event, {:session, _, :begun}}, state) do
    log_event("session begun")

    new_state = State.set_session_status(state, :begun)

    send(self(), :attach_receiver)

    {:noreply, [], new_state}
  end

  @impl GenStage
  def handle_info(:attach_receiver, state) do
    log_command("attach")

    {:ok, session} = state.amqp.client_module.attach(state.amqp)

    new_state = State.set_receiver(state, session)

    {:noreply, [], new_state}
  end

  @impl GenStage
  def handle_info({:amqp10_event, {:link, {:link_ref, :receiver, _, _}, :attached}}, state) do
    log_event("attached")

    new_state = State.set_receiver_status(state, :attached)

    send(self(), :maybe_ask_credits)

    {:noreply, [], new_state}
  end

  @impl GenStage
  def handle_info(
        {:amqp10_event,
         {:link, {:link_ref, :receiver, _, _},
          {:detached, {:"v1_0.error", {:symbol, error_title}, {:utf8, error_message}, _}}}},
        state
      ) do
    Logger.error(
      "off_broadway_amqp10 session detached with error [#{error_title}], message: [#{error_message}]"
    )

    {:stop, error_title, state}
  end

  @impl GenStage
  def handle_info(:maybe_ask_credits, state) do
    if State.has_demand?(state) && State.receiver_attached?(state) do
      credits = State.credits_within_limits(state)
      log_command("ask for credits(#{credits})")

      :ok = state.amqp.client_module.flow_link_credit(state.amqp, credits)
    end

    {:noreply, [], state}
  end

  @impl GenStage
  def handle_info(
        {:amqp10_event, {:link, {:link_ref, :receiver, _, _}, :credit_exhausted}},
        state
      ) do
    log_event("credit exhausted")

    send(self(), :maybe_ask_credits)

    {:noreply, [], state}
  end

  @impl GenStage
  def handle_info({:amqp10_msg, {:link_ref, :receiver, _, _}, msg}, state) do
    client_module = state.amqp.client_module
    payload = client_module.body(msg)

    metadata = %{
      headers: client_module.headers(msg),
      properties: client_module.properties(msg),
      application_properties: client_module.application_properties(msg),
      annotations: client_module.annotations(msg)
    }

    acknowledger = {OffBroadwayAmqp10.Acknowledger, state.amqp, msg}

    message = %Message{
      data: payload,
      metadata: metadata,
      acknowledger: acknowledger
    }

    new_state = State.decrease_demand(state, 1)
    {:noreply, [message], new_state}
  end

  defp log_event(msg) do
    Logger.debug("#{__MODULE__}:#{inspect(self())} Event: #{msg}")
  end

  defp log_command(msg) do
    Logger.debug("#{__MODULE__}:#{inspect(self())} Command: #{msg}")
  end
end
