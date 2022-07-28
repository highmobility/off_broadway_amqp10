defmodule OffBroadwayAmqp10.Acknowledger do
  @moduledoc """
  AMQP Broadway Ackoledger
  """
  alias Broadway.Acknowledger

  @behaviour Acknowledger

  @impl Acknowledger
  def ack(amqp_state, successful, failed) do
    ack_messages(successful, amqp_state, :successful)
    ack_messages(failed, amqp_state, :failed)
  end

  defp ack_messages(_failed, _amqp_state, :failed) do
    :ok
  end

  defp ack_messages(successful, amqp_state, :successful) do
    for %{acknowledger: {_module, _receiver, ack_data}} = msg <- successful do
      :ok = amqp_state.client_module.accept_msg(amqp_state, ack_data)
      msg.data
    end

    :ok
  end
end
