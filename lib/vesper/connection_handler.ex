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

  defp handle_sender(room, send_socket, state) do
    case Vesper.RoomRegistry.lookup_receiver(room) do
      [{_pid, recv_socket}] ->
        Logger.debug("Established send-recieve pipe.")
        {
          :continue,
          state
          |> Map.put(:role, :sender)
          |> Map.put(:recv_socket, recv_socket)
          |> Map.put(:room, room)
        }

      _ ->
        Logger.debug("Could not find receiver for room #{room}; closing sender connection.")
        close_socket_rudely(send_socket, state)
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
