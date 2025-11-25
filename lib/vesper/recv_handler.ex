defmodule Vesper.RecvHandler do
  alias Vesper.HandlerUtils
  require Logger
  use ThousandIsland.Handler

  @impl ThousandIsland.Handler
  def handle_connection(_socket, _state) do
    {:continue, %{}}
  end

  @impl ThousandIsland.Handler
  def handle_data(data, socket, state) when state == %{} do
    with {:ok, room} <- HandlerUtils.validate_room(data, state),
         :ok         <- register_receiver(room, socket, state) do
      {:continue, %{room: room}}
    end
  end

  @impl ThousandIsland.Handler
  def handle_data(_data, _socket, %{room: room} = state) do
    Logger.warning("Received unexpected data from receiver for room #{room}, closing connection.")
    {:close, state}
  end

  defp register_receiver(room, socket, state) do
    case Vesper.RoomRegistry.register_receiver(room, socket) do
      {:ok, _} -> :ok
      _        -> {:close, state}
    end
  end
end
