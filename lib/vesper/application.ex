defmodule Vesper.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Vesper.RoomRegistry,
      {ThousandIsland, port: 3000, handler_module: Vesper.ConnectionHandler}
    ]

    opts = [strategy: :one_for_one, name: Vesper.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
