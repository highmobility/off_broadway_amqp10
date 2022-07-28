defmodule OffBroadwayAmqp10.Amqp10.Client do
  @moduledoc """
  AMQP 1.0 Client wrapper behaviour
  """

  alias OffBroadwayAmqp10.Amqp10.State

  @type annotations_key() :: binary() | non_neg_integer()
  @type annotations_keys() :: %{annotations_key() => any()}

  @callback open_connection(State.t()) :: Supervisor.on_start_child()
  @callback begin_session(State.t()) :: Supervisor.on_start_child()
  @callback attach(State.t()) :: {:ok, State.receiver()}
  @callback flow_link_credit(State.t(), non_neg_integer()) :: :ok
  @callback accept_msg(State.t(), State.raw_message()) :: :ok

  # Parsing
  @callback body(State.raw_message()) :: binary()
  @callback headers(State.raw_message()) :: :amqp10_msg.amqp10_header()
  @callback properties(State.raw_message()) :: :amqp10_msg.amqp10_properties()
  @callback application_properties(State.raw_message()) :: :amqp10_msg.amqp10_properties()
  @callback annotations(State.raw_message()) :: annotations_keys()
end
