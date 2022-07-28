defmodule OffBroadwayAmqp10.Producer.State do
  @moduledoc false
  alias OffBroadwayAmqp10.Amqp10
  alias OffBroadwayAmqp10.Producer.Params

  @type t() :: %__MODULE__{
          demand: non_neg_integer(),
          credit_limit: non_neg_integer(),
          amqp: nil | Amqp10.State.t()
        }

  defstruct [:demand, :credit_limit, :amqp]

  @spec new(Keyword.t()) :: t()
  def new(opts) do
    valid_opts = Params.validate!(opts)

    %__MODULE__{
      demand: 0,
      credit_limit: get_in(valid_opts, [:connection, :transfer_limit_margin]),
      amqp: Amqp10.State.new(valid_opts)
    }
  end

  @spec increase_demand(t(), non_neg_integer()) :: t()
  def increase_demand(%__MODULE__{} = state, value) when value >= 0 do
    %__MODULE__{state | demand: state.demand + value}
  end

  @spec decrease_demand(t(), non_neg_integer()) :: t()
  def decrease_demand(%__MODULE__{} = state, value) when value >= 0 do
    new_value = max(state.demand - value, 0)
    %__MODULE__{state | demand: new_value}
  end

  @spec set_connection(t(), pid()) :: t()
  def set_connection(%__MODULE__{} = state, connection) do
    new_amqp =
      state.amqp
      |> Amqp10.State.set_connection(connection)
      |> Amqp10.State.set_connection_status(:initialized)

    %__MODULE__{state | amqp: new_amqp}
  end

  @spec set_connection_status(t(), Amqp10.State.connection_status()) :: t()
  def set_connection_status(%__MODULE__{} = state, status) do
    new_amqp = Amqp10.State.set_connection_status(state.amqp, status)

    %__MODULE__{state | amqp: new_amqp}
  end

  @spec set_session(t(), pid()) :: t()
  def set_session(%__MODULE__{} = state, session) do
    new_amqp =
      state.amqp
      |> Amqp10.State.set_session(session)
      |> Amqp10.State.set_session_status(:initialized)

    %__MODULE__{state | amqp: new_amqp}
  end

  @spec set_session_status(t(), Amqp10.State.session_status()) :: t()
  def set_session_status(%__MODULE__{} = state, status) do
    new_amqp = Amqp10.State.set_session_status(state.amqp, status)

    %__MODULE__{state | amqp: new_amqp}
  end

  @spec set_receiver(t(), pid()) :: t()
  def set_receiver(%__MODULE__{} = state, receiver) do
    new_amqp =
      state.amqp
      |> Amqp10.State.set_receiver(receiver)
      |> Amqp10.State.set_receiver_status(:initialized)

    %__MODULE__{state | amqp: new_amqp}
  end

  @spec set_receiver_status(t(), Amqp10.State.receiver_status()) :: t()
  def set_receiver_status(%__MODULE__{} = state, status) do
    new_amqp = Amqp10.State.set_receiver_status(state.amqp, status)

    %__MODULE__{state | amqp: new_amqp}
  end

  @spec has_demand?(t()) :: boolean()
  def has_demand?(%__MODULE__{demand: demand}) do
    demand > 0
  end

  @spec credits_within_limits(t()) :: non_neg_integer()
  def credits_within_limits(%__MODULE__{credit_limit: credit_limit, demand: demand}) do
    min(demand, credit_limit)
  end

  @spec receiver_attached?(t()) :: boolean()
  def receiver_attached?(%__MODULE__{} = state) do
    Amqp10.State.receiver_attached?(state.amqp)
  end
end
