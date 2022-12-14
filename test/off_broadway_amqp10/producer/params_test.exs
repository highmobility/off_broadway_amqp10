defmodule OffBroadwayAmqp10.Producer.ParamsTest do
  use ExUnit.Case, async: true

  alias OffBroadwayAmqp10.Producer.Params, as: SUT

  test "validates configuration" do
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

    opts = [
      queue: "some_queue",
      connection: connection_opts,
      session: session_opts,
      client_module: OffBroadwayAmqp10.Amqp10.Client.Impl
    ]

    assert SUT.validate!(opts)
  end
end
