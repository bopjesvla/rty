defmodule Mafia.MeetChannel do
  use Mafia.Web, :channel

  alias Mafia.{Repo, Channel, Message, User, Pengine, Game, GameServer}

  def player(meet, socket) do
    Repo.get_by!(Mafia.GameSlot, user_id: socket.assigns.user, game_id: meet.game_id)
  end

  def join("meet:" <> name, _payload, socket) do
    player = Repo.get_by!(Channel, name: name, type: "meet")
    |> player(socket)

    GameServer.query! player.game_id, {:join_channel, player.id, name}

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
      broadcast! socket, "new:msg", %{msg: msg, u: socket.assigns.user, ts: inserted_at, type: "m"}
      {:noreply, socket}
    else
      {:error, "invalid message"}
    end
  end

  def handle_in("new:vote", %{"action" => action, "targets" => targets}, socket) do
    "meet:" <> name = socket.topic

    player = Repo.get_by!(Channel, name: name, type: "meet")
    |> player(socket)

    targets = Enum.map targets, fn
      t when is_integer(t) ->
        Repo.get_by!(Mafia.GameSlot, user_id: t, game_id: player.game_id).id
      t -> t
    end

    GameServer.query! player.game_id, {:vote, player.id, name, String.to_existing_atom(action), targets}
    {:reply, :ok, socket}
  end

  intercept ["leave"]
  def handle_out("leave", %{who: who}, socket) do
    push socket, "new:msg", %{type: "leave"}

    case who do
      :all ->
        {:stop, :normal, socket}
      who ->
        if socket.assigns.user in who do
          {:stop, :normal, socket}
        else
          {:noreply, socket}
        end
    end
  end

  def new_message(meet, type, user, message) do
    channel = Repo.get_by(Channel, name: meet, type: "meet")
    %{inserted_at: inserted_at} = Repo.insert!(%Message{channel: channel, user_id: user, type: type, msg: message})

    Mafia.Endpoint.broadcast! "meet:#{meet}", "new:msg", %{msg: message, u: user, ts: inserted_at, type: type}
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end
end
