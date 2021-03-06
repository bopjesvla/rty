defmodule Mafia.MeetChannel do
  use Mafia.Web, :channel

  alias Mafia.{Repo, Channel, Message, User, Game, GameServer}

  def join("meet:" <> name, _payload, socket) do
    meet = Repo.get_by!(Channel, name: name, type: "meet")
    player = Mafia.Queries.player!(meet.game_id, socket.assigns.user)

    GameServer.query! meet.game_id, {:join_channel, player.game_slot_id, name}

    {:ok, socket}
  end

  def join("talk:" <> game_id, _params, socket) do
    game = Repo.get!(Game, game_id)

    if game.status == "ongoing" do
      raise "Ongoing"
    end

    {:ok, %{}, socket}
  end

  def channel("meet:" <> name), do: Repo.get_by!(Channel, name: name)
  def channel("talk:" <> game_id) do
    Repo.get_by!(Channel, game_id: game_id, type: "talk")
  end

  def handle_in("new:msg", %{"msg" => msg}, socket) do
    if String.printable?(msg) do
      %{id: id} = channel(socket.topic)

      %{inserted_at: inserted_at} = Repo.insert! Message.changeset(%Message{channel_id: id, user_id: socket.assigns.user}, %{type: "m", msg: msg})
      broadcast! socket, "new:msg", %{msg: msg, u: socket.assigns.user, ts: inserted_at, ty: "m"}
      {:noreply, socket}
    else
      {:error, "invalid message"}
    end
  end

  def handle_in("new:vote", %{"act" => action, "opt" => targets}, socket) do
    "meet:" <> name = socket.topic

    meet = Repo.get_by!(Channel, name: name, type: "meet")
    player = Mafia.Queries.player!(meet.game_id, socket.assigns.user)

    targets = Enum.map targets, fn
      t when is_binary(t) -> String.to_existing_atom(t)
      t -> t
    end

    GameServer.query! meet.game_id, {:vote, player.game_slot_id, name, String.to_existing_atom(action), targets}
    {:reply, :ok, socket}
  end

  intercept ["leave"]
  def handle_out("leave", %{who: who}, %{assigns: %{user: u}} = socket) do
    case who do
      :all ->
        {:stop, :normal, socket}
      ^u ->
        {:stop, :normal, socket}
      _ ->
        {:noreply, socket}
    end
  end

  def new_message(meet, type, user, message) do
    channel = channel(meet)
    %{inserted_at: inserted_at} = Repo.insert!(%Message{channel: channel, user_id: user, type: type, msg: message})

    Mafia.Endpoint.broadcast! meet, "new:msg", %{msg: message, u: user, ts: inserted_at, ty: type}
  end

  def leave_message(meet, who) do
    channel = channel(meet)
    %{inserted_at: inserted_at} = Repo.insert!(%Message{channel: channel, user_id: who, type: "leave", msg: nil})

    Mafia.Endpoint.broadcast! meet, "leave", %{who: who || :all}
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end
end
