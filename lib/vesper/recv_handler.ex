defmodule Vesper.RecvHandler do
  require Logger
  use ThousandIsland.Handler

  @impl ThousandIsland.Handler
  def handle_connection(_socket, _state) do
    {:continue, %{}}
  end

  @impl ThousandIsland.Handler
  def handle_data(data, socket, state) when state == %{} do
    room_name = String.trim(data)

    case Vesper.RoomRegistry.register_receiver(room_name, socket) do
      {:ok, _} -> {:continue, %{room: room_name}}
      _        -> {:close, state}
    end
  end

  @impl ThousandIsland.Handler
  def handle_data(_data, _socket, %{room: room} = state) do
    Logger.warning("Received unexpected data from receiver for room #{room}, closing connection.")
    {:close, state}
  end
end
