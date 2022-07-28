defmodule OffBroadwayAmqp10.AcceptanceTest do
  use ExUnit.Case, async: false

  defmodule BroadwayInstance do
    use Broadway

    def handle_message(_, message, %{test_pid: test_pid}) do
      send(test_pid, {__MODULE__, :handle_message, message})
      message
    end
  end

  defp start_broadway do
    config = Fixture.configuration(client_module: RealisticFakeAmqpClient)

    {:ok, _pid} =
      Broadway.start_link(BroadwayInstance,
        name: __MODULE__,
        context: %{test_pid: self()},
        producer: [
          module: {OffBroadwayAmqp10.Producer, config},
          concurrency: 1
        ],
        processors: [
          default: [concurrency: 1]
        ]
      )
  end

  test "delivers message to broadway instance" do
    {:ok, _amqp_client} = RealisticFakeAmqpClient.start_link(self())
    {:ok, _broadway_pid} = start_broadway()

    # Connection
    assert_receive {RealisticFakeAmqpClient, :open_connection_called, _}
    :ok = RealisticFakeAmqpClient.send_connection_opened()

    assert_receive {RealisticFakeAmqpClient, :begin_session_called, _}
    :ok = RealisticFakeAmqpClient.send_session_begun()

    assert_receive {RealisticFakeAmqpClient, :attach_called, _}
    :ok = RealisticFakeAmqpClient.send_attached()

    assert_receive {RealisticFakeAmqpClient, :flow_link_credit_called, [_demand = 10, _, _]}

    # Messages
    for i <- 0..15 do
      :ok = RealisticFakeAmqpClient.send_msg("Message #{i}")
    end

    for i <- 0..15 do
      data = "Message #{i}"
      assert_receive {BroadwayInstance, :handle_message, %Broadway.Message{data: ^data}}
      assert_receive {RealisticFakeAmqpClient, :accept_msg, _}
    end

    assert_receive {RealisticFakeAmqpClient, :flow_link_credit_called, [_, _, _]}
  end
end
