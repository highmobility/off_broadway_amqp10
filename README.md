# OffBroadwayAmqp10

[![Build Status](https://github.com/highmobility/off_broadway_amqp10/actions/workflows/ci.yml/badge.svg)](https://github.com/highmobility/off_broadway_amqp10/actions/workflows/ci.yml)
[![Docs](https://img.shields.io/badge/api-docs-green.svg?style=flat)](https://hexdocs.pm/off_broadway_amqp10)
[![Hex.pm Version](https://img.shields.io/hexpm/v/off_broadway_amqp10.svg?style=flat)](https://hex.pm/packages/off_broadway_amqp10)


An AMQP 1.0 connector for [Broadway](https://hexdocs.pm/broadway).


## Installation

The package can be installed
by adding `off_broadway_amqp10` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:off_broadway_amqp10, "~> 0.1.1"}
  ]
end
```

## TODO

- [ ] Handle connection errors
- [ ] Handle session errors
- [ ] Backoff strategy to re-connect in case of an error
- [ ] Handle body type: `[#'v1_0.amqp_sequence'{}]` specified in this [doc](https://hexdocs.pm/amqp10_client/amqp10_msg.html#body-1) and this [PR](https://github.com/highmobility/off_broadway_amqp10/pull/114).
