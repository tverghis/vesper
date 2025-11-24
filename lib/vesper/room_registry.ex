defmodule Vesper.RoomRegistry do
  require Logger

  def start_link do
    Logger.info("Starting room registry.")
    Registry.start_link(keys: :unique, name: __MODULE__)
  end

  def child_spec(_) do
    Supervisor.child_spec(
      Registry,
      id: __MODULE__,
      start: {__MODULE__, :start_link, []}
    )
  end

  def register_receiver(room, socket) do
    Registry.register(__MODULE__, {:receiver, room}, socket)
  end
end
