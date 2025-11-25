defmodule Vesper.HandlerUtils do
  def validate_room(room, state) do
    room_name = String.trim(room)

    case room_name do
      "" -> {:close, state}
      _ -> {:ok, room_name}
    end
  end
end
