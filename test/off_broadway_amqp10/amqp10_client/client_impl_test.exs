defmodule OffBroadwayAmqp10.Amqp10.Client.ImplTest do
  use ExUnit.Case, async: true

  alias OffBroadwayAmqp10.Amqp10.Client.Impl, as: SUT

  describe "body/1" do
    test "extracts body" do
      assert SUT.body(Fixture.raw_msg()) == "Itachi"
    end
  end

  describe "headers/1" do
    test "extracts headers" do
      assert SUT.headers(Fixture.raw_msg()) == %{
               delivery_count: 0,
               durable: false,
               first_acquirer: false,
               priority: 4
             }
    end
  end

  describe "properties/1" do
    test "extracts properties" do
      assert SUT.properties(Fixture.raw_msg()) == %{
               absolute_expiry_time: 1_658_155_022_583,
               creation_time: 1_656_945_422_583,
               message_id: "00000000000000000000000000000000"
             }
    end
  end

  describe "application_properties/1" do
    test "extracts application properties" do
      assert SUT.application_properties(Fixture.raw_msg()) == %{"bar" => "baz", "foo" => "bar"}
    end
  end

  describe "annotations/1" do
    test "extracts annotations" do
      assert SUT.annotations(Fixture.raw_msg()) == %{
               "x-opt-enqueued-time" => 1_656_945_422_583,
               "x-opt-sequence-number" => 6068
             }
    end
  end
end
