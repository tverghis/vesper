defmodule Vesper.ConnectionHandler do
  use ThousandIsland.Handler

  require Logger
  alias ThousandIsland.Socket

  @goaway "GOAWAY\n"

  @impl ThousandIsland.Handler
  def handle_connection(_socket, _state) do
    {:continue, %{role: :unknown}}
  end

  @impl ThousandIsland.Handler
  def handle_data(data, socket, %{role: role} = state) when role == :unknown do
    case String.trim(data) do
      "send|" <> room when room != "" -> handle_sender(room, socket, state)
      "recv|" <> room when room != "" -> handle_receiver(room, socket, state)
      _ ->
        Logger.warning("Received invalid role message, closing connection.")
        close_socket_rudely(socket, state)
    end
  end

  @impl ThousandIsland.Handler
  def handle_data(data, socket, %{role: role, room: room, recv_socket: recv_socket} = state) when role == :sender do
    case Socket.send(recv_socket, data) do
      :ok -> {:continue, state}
      _ ->
        Logger.debug("Failed to send data to receiver for room #{room}; closing sender connection.")
        close_socket_rudely(socket, state)
    end
  end

  @impl ThousandIsland.Handler
  def handle_data(_data, socket, %{role: role, room: room} = state) when role == :receiver do
    Logger.warning("Received unexpected data from receiver for room #{room}, closing connection.")
    close_socket_rudely(socket, state)
  end

  defp handle_sender(room, socket, state) do
    with :ok         <- register_sender(socket, room, state),
         recv_socket <- find_recv_socket(socket, room, state) do
      Logger.debug("Established send-recieve pipe.")
      new_state = state
        |> Map.put(:role, :sender)
        |> Map.put(:recv_socket, recv_socket)
        |> Map.put(:room, room)
      {:continue, new_state}
    end
  end

  defp register_sender(send_socket, room, state) do
    case Vesper.RoomRegistry.register_sender(room) do
      {:ok, _} -> :ok
      _ -> close_socket_rudely(send_socket, state)
    end
  end

  defp find_recv_socket(send_socket, room, state) do
    case Vesper.RoomRegistry.lookup_receiver(room) do
      [{_, recv_socket}] -> recv_socket
      _ -> close_socket_rudely(send_socket, state)
    end
  end

  defp handle_receiver(room, socket, state) do
    Logger.debug("Registering reciever for room #{room}.")
    case Vesper.RoomRegistry.register_receiver(room, socket) do
      {:ok, _} -> {:continue, %{role: :receiver, room: room}}
      _ -> close_socket_rudely(socket, state)
    end
  end

  defp close_socket_rudely(socket, state) do
    Socket.send(socket, @goaway)
    {:close, state}
  end
end
