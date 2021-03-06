defmodule Mafia.GameChannel do
  use Phoenix.Channel

  alias Mafia.{Repo, Channel, Message, User, Game, GameSlot, GameSupervisor, GameServer, Queries}
  import Ecto.Query

  #def handle_in("room_info", %{id: id}, socket) do
    #case Repo.get_by(Room, id: id) do
      #nil -> nil
    #end
  #end

  def join("game:" <> id, _, %{assigns: %{user: user}} = socket) do
    id = String.to_integer(id)
    %{status: "playing"} = Queries.player!(id, user)

    # messages = Repo.run! :game_messages_for_user, [user, id]

    info = Queries.game_info_and_messages(id, user)
    
    {:ok, info, socket}
  end

  def new_message(game_id, type, user, message) do
    channel = Repo.get_by!(Channel, game_id: game_id, type: "game")
    %{inserted_at: inserted_at} = Repo.insert!(%Message{channel: channel, user_id: user, type: type, msg: message})

    Mafia.Endpoint.broadcast! "game:#{game_id}", "new:msg",
      %{msg: message, u: user, ts: inserted_at, ty: type}
  end

  def handle_in("info", _, socket) do
    "game:" <> id = socket.topic
    {:reply, {:ok, Queries.game_info(id, socket.assigns.user)}, socket}
  end
end
