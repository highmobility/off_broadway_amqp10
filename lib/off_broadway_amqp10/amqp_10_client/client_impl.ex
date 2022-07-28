defmodule OffBroadwayAmqp10.Amqp10.Client.Impl do
  @moduledoc """
  AMQP Client Wrapper
  """

  alias OffBroadwayAmqp10.Amqp10.State
  alias OffBroadwayAmqp10.Amqp10.Client

  @behaviour Client

  @impl Client
  def open_connection(%State{} = state) do
    :amqp10_client.open_connection(state.connection_config)
  end

  @impl Client
  def begin_session(%State{} = state) do
    :amqp10_client.begin_session(state.connection)
  end

  @impl Client
  def attach(%State{} = state) do
    :amqp10_client_session.attach(state.session, state.receiver_config)
  end

  @impl Client
  def flow_link_credit(%State{} = state, demand) do
    :amqp10_client.flow_link_credit(state.receiver, demand, :never)
  end

  @impl Client
  def accept_msg(%State{} = state, ack_data) do
    :amqp10_client.accept_msg(state.receiver, ack_data)
  end

  @impl Client
  def body(raw_msg) do
    [payload] = :amqp10_msg.body(raw_msg)
    payload
  end

  @impl Client
  def headers(raw_msg) do
    :amqp10_msg.headers(raw_msg)
  end

  @impl Client
  def properties(raw_msg) do
    :amqp10_msg.properties(raw_msg)
  end

  @impl Client
  def application_properties(raw_msg) do
    :amqp10_msg.application_properties(raw_msg)
  end

  @impl Client
  def annotations(raw_msg) do
    :amqp10_msg.message_annotations(raw_msg)
  end
end
