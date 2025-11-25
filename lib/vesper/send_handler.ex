defmodule Vesper.SendHandler do
  alias ThousandIsland.Socket
  alias Vesper.HandlerUtils
  require Logger
  use ThousandIsland.Handler

  @impl ThousandIsland.Handler
  def handle_connection(_socket, _state) do
    {:continue, %{}}
  end

  @impl ThousandIsland.Handler
  def handle_data(data, _socket, state) when state == %{} do
    with {:ok, room} <- HandlerUtils.validate_room(data, state),
                 :ok <- register_sender(room, state),
         {:ok, peer} <- find_peer(room, state) do
      new_state = state
        |> Map.put(:peer, peer)
        |> Map.put(:room, room)

      {:continue, new_state}
    end
  end

  @impl ThousandIsland.Handler
  def handle_data(data, _socket, %{peer: peer} = state) do
    case Socket.send(peer, data) do
      :ok -> {:continue, state}
      _   -> {:close, state}
    end
  end

  defp register_sender(room, state) do
    case Vesper.RoomRegistry.register_sender(room) do
      {:ok, _} -> :ok
      _        -> {:close, state}
    end
  end

  defp find_peer(room, state) do
    case Vesper.RoomRegistry.lookup_receiver(room) do
      [{_, recv_socket}] -> {:ok, recv_socket}
      _                  -> {:close, state}
    end
  end
end
