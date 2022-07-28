defmodule OffBroadwayAmqp10.Amqp10.StateTest do
  use ExUnit.Case, async: true

  alias OffBroadwayAmqp10.Amqp10.State, as: SUT

  setup do
    %{state: Fixture.build_amqp_state()}
  end

  describe "new/0" do
    test "builds initial state" do
      assert %SUT{} = SUT.new(Fixture.configuration())
    end
  end

  describe "set_connection/2" do
    test "set connection", %{state: state} do
      connection = self()
      new_state = SUT.set_connection(state, connection)

      assert new_state.connection == connection
    end
  end

  describe "set_connection_status/2" do
    test "set connection status", %{state: state} do
      new_state = SUT.set_connection_status(state, :initialized)

      assert :initialized = new_state.connection_status
    end
  end

  describe "set_session/2" do
    test "set session", %{state: state} do
      session = self()
      new_state = SUT.set_session(state, session)

      assert new_state.session == session
    end
  end

  describe "set_session_status/2" do
    test "set session status", %{state: state} do
      new_state = SUT.set_session_status(state, :initialized)

      assert :initialized = new_state.session_status
    end
  end

  describe "set_receiver/2" do
    test "set receiver", %{state: state} do
      receiver = self()
      new_state = SUT.set_receiver(state, receiver)

      assert new_state.receiver == receiver
    end
  end

  describe "set_receiver_status/2" do
    test "set receiver status", %{state: state} do
      new_state = SUT.set_receiver_status(state, :initialized)

      assert :initialized = new_state.receiver_status
    end
  end

  describe "receiver_attached/1" do
    test "returns true when receiver is attached", %{state: state} do
      state =
        state
        |> SUT.set_receiver(self())
        |> SUT.set_receiver_status(:attached)

      assert SUT.receiver_attached?(state)
    end

    test "returns false when receiver is not attached", %{state: state} do
      state =
        state
        |> SUT.set_receiver(self())
        |> SUT.set_receiver_status(:detached)

      refute SUT.receiver_attached?(state)
    end

    test "returns false when receiver is not present", %{state: state} do
      state =
        state
        |> SUT.set_receiver(nil)
        |> SUT.set_receiver_status(:attached)

      refute SUT.receiver_attached?(state)
    end
  end

  test "hides sensitive information", %{state: state} do
    refute inspect(state) =~ "connection_config"
  end
end
