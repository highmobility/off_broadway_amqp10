defmodule OffBroadwayAmqp10.Producer.Params do
  @moduledoc false
  @connection_opts_schema [
    hostname: [type: :string, required: true, doc: "The hostname"],
    port: [type: :pos_integer, required: true, doc: "The port number"],
    sasl: [
      type:
        {:or,
         [
           {:in, [:none]},
           {:keyword_list,
            [
              mechanism: [
                type: {:in, [:plain]},
                required: true
              ],
              username: [
                type: :string,
                required: true
              ],
              password: [
                type: :string,
                required: true
              ]
            ]}
         ]},
      required: true,
      doc: """
      :none or [mechanism: :plain, username: "foo", password: "bar"]. In Azure Service Bus username is `SharedAccessKeyName` and password is `SharedAccessKey`
      """
    ],
    tls_opts: [
      type: :any,
      required: false,
      doc: """
      Must be `{:secure_port, [:ssl.tls_option()]}`.
      """
    ],
    transfer_limit_margin: [
      type: :pos_integer,
      default: 100,
      doc: "The max amount of credit that could be requested."
    ]
  ]

  @sessions_opts_schema [
    name: [
      type: :string,
      required: true,
      doc: """
      When using topics in Azure Service Bus, it's called `Subscription Name`. Otherwise just an arbitrary name.
      """
    ],
    snd_settle_mode: [
      type: {:in, [:unsettled, :settled, :mixed]},
      default: :mixed,
      doc: """
         `unsettled`: The sender will send all deliveries initially unsettled to the receiver.
         `settled`: The sender will send all deliveries settled to the receiver.
         `mixed`: The sender may send a mixture of settled and unsettled deliveries to the receiver.
      """
    ],
    rcv_settle_mode: [
      type: {:in, [:first, :second]},
      default: :second,
      doc: """
        `first`: The receiver will spontaneously settle all incoming transfers.
        `second`: The receiver will only settle after sending the disposition to the sender and receiving a disposition indicating settlement of the delivery from the sender.
      """
    ]
  ]

  @opts_schema [
    broadway: [
      type: :any,
      doc: false
    ],
    queue: [
      type: :string,
      required: true,
      doc: """
      The name of the queue or topic
      """
    ],
    durable: [
      type: {:in, [:none, :configuration, :unsettled_state]},
      required: false,
      default: :none,
      doc: """
      Receiver durability option based on `t::amqp10_client_session.terminus_durability/0`
      """
    ],
    connection: [
      type: :keyword_list,
      keys: @connection_opts_schema,
      required: true,
      doc: """
      Connection options based on `t::amqp10_client_connection.connection_config/0`
      """
    ],
    session: [
      type: :keyword_list,
      required: true,
      keys: @sessions_opts_schema,
      default: [snd_settle_mode: :mixed, rcv_settle_mode: :second],
      doc: """
      Session options
      """
    ],
    client_module: [
      required: false,
      type: :atom,
      default: OffBroadwayAmqp10.Amqp10.Client.Impl,
      doc: false
    ]
  ]

  @doc false
  def validate!(opts) do
    NimbleOptions.validate!(opts, @opts_schema)
  end

  @doc false
  def __opts_schema__ do
    @opts_schema
  end
end
