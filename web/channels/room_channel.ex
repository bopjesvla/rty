defmodule Mafia.RoomChannel do
  use Phoenix.Channel

  alias Mafia.{Repo, Channel, Subchannel, Message, User}
  import Ecto.Query, only: [from: 2]

  def join("rooms", prams, socket) do
    {:ok, socket}
  end

  #def handle_in("room_info", %{name: name}, socket) do
    #case Repo.get_by(Room, name: name) do
      #nil -> nil
    #end
  #end

  def join("room:" <> name, params, socket) do
    case Repo.get_by(Channel, name: name, type: "room") do
      nil ->
        Repo.transaction(fn ->
          channel = %Channel{name: name, user_id: socket.assigns.user, type: "room"}
                    |> Repo.insert!

         #Repo.insert! %Room{name: name, creator_id: socket.assigns.user, archived: false, type: "room"}
          #Repo.insert! %Channel{room_id: room_id}
          #Repo.insert! %Subchannel
        end)
        {:ok, %{msgs: []}, socket}
      %{type: "room", id: id} ->
        messages = Repo.all from m in Message,
        join: u in assoc(m, :user),
        where: m.channel_id == ^id,
        select: %{msg: m.msg, u: u.name, ts: m.inserted_at, ty: m.type},
        order_by: m.inserted_at

        #channels = Repo.get_by(Channel, room_id: id)
        {:ok, %{msgs: messages}, socket}
    end
  end

  def handle_in("new:msg", %{"msg" => msg}, socket) do
    "room:" <> name = socket.topic
    if String.printable?(msg) do
      %{id: id} = Repo.get_by Channel, name: name, type: "room"

      username = Repo.one! from u in User, where: u.id == ^socket.assigns.user, select: u.name
      %{inserted_at: inserted_at} = Repo.insert! %Message{type: "m", msg: msg, channel_id: id, user_id: socket.assigns.user}
      broadcast! socket, "new:msg", %{msg: msg, u: username, ts: inserted_at, ty: "m"}
      {:noreply, socket}
    else
      {:error, "invalid message"}
    end
  end
end
