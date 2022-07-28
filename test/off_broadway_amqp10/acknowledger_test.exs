defmodule OffBroadwayAmqp10.AcknowledgerTest do
  use ExUnit.Case, async: true

  alias OffBroadwayAmqp10.Acknowledger, as: SUT

  describe "ack/3" do
    setup do
      amqp_state = Fixture.build_amqp_state()

      raw_msg = :msg_foo

      message = %Broadway.Message{
        data: raw_msg,
        metadata: %{},
        acknowledger: {OffBroadwayAmqp10.Acknowledger, amqp_state, raw_msg}
      }

      %{raw_msg: raw_msg, message: message, amqp_state: amqp_state}
    end

    test "acknowledges successful messages", %{
      raw_msg: raw_msg,
      message: message,
      amqp_state: amqp_state
    } do
      assert :ok = SUT.ack(amqp_state, [message], [])

      assert_receive {FakeAmqpClient, :accept_msg_called,
                      [%OffBroadwayAmqp10.Amqp10.State{}, ^raw_msg]}
    end

    test "does not acknowledge failed messages", %{message: message, amqp_state: amqp_state} do
      assert :ok = SUT.ack(amqp_state, [], [message])

      refute_receive {FakeAmqpClient, :accept_msg_called, _}
    end
  end
end
