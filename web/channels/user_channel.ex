defmodule Mafia.UserChannel do
  use Mafia.Web, :channel

  def join("user:" <> user, payload, socket) do
    if String.to_integer(user) == socket.assigns.user do
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_in("list:games", _, socket) do
    games = Repo.all from g in Mafia.Game,
    join: p in assoc(g, :players),
    join: s in assoc(g, :setup),
    where: p.user_id == ^socket.assigns.user and p.status == "playing"
    and (g.status == "ongoing" or g.status == "signups"),
    select: %{
      id: g.id,
      setup: s.name,
      speed: g.speed,
      status: g.status
    }
    {:reply, {:ok, %{games: games}}, socket}
  end

  def handle_in("get:archive", %{"id" => id}, socket) do
    game = Repo.get! Mafia.Game, id
    if game.status in ~w(ended crashed) do
      info = Mafia.Queries.game_info_and_messages(id, socket.assigns.user)
      {:reply, {:ok, info}, socket}
    else
      {:reply, :ok, socket}
    end
  end
end
