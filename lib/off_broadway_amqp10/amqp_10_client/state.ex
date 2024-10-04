defmodule OffBroadwayAmqp10.Amqp10.State do
  @moduledoc false

  @derive {Inspect, except: [:connection_config]}

  @type receiver :: {:link_ref, :receiver, pid(), non_neg_integer()}
  @type raw_message :: :amqp10_msg.amqp10_msg()

  @type t() :: %__MODULE__{
          client_module: module(),
          connection: nil | pid(),
          connection_config: map(),
          connection_status: connection_status(),
          session: nil | pid(),
          session_status: session_status(),
          receiver: nil | receiver(),
          receiver_config: map(),
          receiver_status: receiver_status()
        }

  defstruct [
    :client_module,
    :connection_config,
    :connection,
    :connection_status,
    :session,
    :session_status,
    :receiver,
    :receiver_config,
    :receiver_status
  ]

  @type connection_status :: nil | :initialized | :open
  @connection_status [:initialized, :open]

  @type session_status :: nil | :initialized | :begun
  @session_status [:initialized, :begun]

  @type receiver_status :: nil | :initialized | :attached | :detached
  @receiver_status [:initialized, :initialized, :attached, :detached]

  @type general_config :: %{connection: keyword(), receiver: map(), client_module: module()}

  @spec new(Keyword.t()) :: t()
  def new(opts) do
    %__MODULE__{
      client_module: Keyword.fetch!(opts, :client_module),
      connection_config: connection_config(opts),
      connection: nil,
      connection_status: nil,
      session: nil,
      session_status: nil,
      receiver: nil,
      receiver_status: nil,
      receiver_config: receiver_config(opts)
    }
  end

  @spec set_connection(t(), pid()) :: t()
  def set_connection(%__MODULE__{} = state, connection) do
    %__MODULE__{state | connection: connection}
  end

  @spec set_connection_status(t(), connection_status()) :: t()
  def set_connection_status(%__MODULE__{} = state, status) when status in @connection_status do
    %__MODULE__{state | connection_status: status}
  end

  @spec set_session(t(), pid()) :: t()
  def set_session(%__MODULE__{} = state, session) do
    %__MODULE__{state | session: session}
  end

  @spec set_session_status(t(), session_status()) :: t()
  def set_session_status(%__MODULE__{} = state, status) when status in @session_status do
    %__MODULE__{state | session_status: status}
  end

  @spec set_receiver(t(), pid()) :: t()
  def set_receiver(%__MODULE__{} = state, receiver) do
    %__MODULE__{state | receiver: receiver}
  end

  @spec set_receiver_status(t(), receiver_status()) :: t()
  def set_receiver_status(%__MODULE__{} = state, status) when status in @receiver_status do
    %__MODULE__{state | receiver_status: status}
  end

  @spec receiver_attached?(t()) :: boolean()
  def receiver_attached?(%__MODULE__{} = state) do
    state.receiver && state.receiver_status == :attached
  end

  defp connection_config(opts) do
    %{
      hostname: get_in(opts, [:connection, :hostname]),
      address: String.to_charlist(get_in(opts, [:connection, :hostname])),
      port: get_in(opts, [:connection, :port]),
      sasl: sasl_config(opts),
      tls_opts: get_in(opts, [:connection, :tls_opts]),
      transfer_limit_margin: get_in(opts, [:connection, :transfer_limit_margin])
    }
  end

  defp sasl_config(opts) do
    case get_in(opts, [:connection, :sasl]) do
      :none ->
        :none

      _ ->
        {
          get_in(opts, [:connection, :sasl, :mechanism]),
          get_in(opts, [:connection, :sasl, :username]),
          get_in(opts, [:connection, :sasl, :password])
        }
    end
  end

  defp receiver_config(opts) do
    %{
      name: get_in(opts, [:session, :name]),
      role:
        {:receiver,
         %{
           address: get_in(opts, [:queue]),
           durable: get_in(opts, [:durable])
         }, self()},
      snd_settle_mode: get_in(opts, [:session, :snd_settle_mode]),
      rcv_settle_mode: get_in(opts, [:session, :rcv_settle_mode]),
      filter: %{},
      properties: %{}
    }
  end
end
