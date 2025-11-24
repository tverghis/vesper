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
      "send|" <> room when room != "" ->
        Logger.debug("Established sender connection for room #{room}.")
        {:continue, %{role: :sender, room: room}}
      "recv|" <> room when room != "" ->
        Logger.debug("Established receiver connection for room #{room}.")
        {:continue, %{role: :receiver, room: room}}
      _ ->
        Logger.warning("Received invalid role message, closing connection.")
        close_socket_rudely(socket, state)
    end
  end

  @impl ThousandIsland.Handler
  def handle_data(_data, _socket, %{role: role} = state) when role == :sender do
    {:continue, state}
  end

  @impl ThousandIsland.Handler
  def handle_data(_data, socket, %{role: role, room: room} = state) when role == :receiver do
    Logger.warning("Received unexpected data from receiver for room #{room}, closing connection.")
    close_socket_rudely(socket, state)
  end

  defp close_socket_rudely(socket, state) do
    Socket.send(socket, @goaway)
    {:close, state}
  end
end
