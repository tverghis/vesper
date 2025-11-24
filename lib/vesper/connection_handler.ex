defmodule Vesper.ConnectionHandler do
  use ThousandIsland.Handler

  require Logger
  alias ThousandIsland.Socket

  @impl ThousandIsland.Handler
  def handle_connection(_socket, _state) do
    {:continue, %{role: :unknown}}
  end

  @impl ThousandIsland.Handler
  def handle_data(data, socket, %{role: role} = state) when role == :unknown do
    case String.trim(data) do
      "send|" <> room when room != "" -> handle_sender(room, state)
      "recv|" <> room when room != "" -> handle_receiver(room, socket, state)
      _                               -> {:close, state}
    end
  end

  @impl ThousandIsland.Handler
  def handle_data(data, _socket, %{role: role, recv_socket: recv_socket} = state) when role == :sender do
    case Socket.send(recv_socket, data) do
      :ok -> {:continue, state}
      _   -> {:close, state}
    end
  end

  @impl ThousandIsland.Handler
  def handle_data(_data, _socket, %{role: role, room: room} = state) when role == :receiver do
    Logger.warning("Received unexpected data from receiver for room #{room}, closing connection.")
    {:close, state}
  end

  defp handle_sender(room, state) do
    with :ok         <- register_sender(room, state),
         recv_socket <- find_recv_socket(room, state) do
      new_state = state
        |> Map.put(:role, :sender)
        |> Map.put(:recv_socket, recv_socket)
        |> Map.put(:room, room)

      {:continue, new_state}
    end
  end

  defp register_sender(room, state) do
    case Vesper.RoomRegistry.register_sender(room) do
      {:ok, _} -> :ok
      _        -> {:close, state}
    end
  end

  defp find_recv_socket(room, state) do
    case Vesper.RoomRegistry.lookup_receiver(room) do
      [{_, recv_socket}] -> recv_socket
      _                  -> {:close, state}
    end
  end

  defp handle_receiver(room, socket, state) do
    case Vesper.RoomRegistry.register_receiver(room, socket) do
      {:ok, _} -> {:continue, %{role: :receiver, room: room}}
      _        -> {:close, state}
    end
  end
end
