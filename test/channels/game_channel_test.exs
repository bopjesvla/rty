defmodule Mafia.GameChannelTest do
  use Mafia.ChannelCase

  alias Mafia.GameChannel

  @setup %{
    teams: [%{player: 1, team: "m"}, %{player: 2, team: "t"}, %{player: 3, team: "t"}, %{player: 4, team: "t"}],
    roles: [%{type: "global", player: nil, team: nil, mods: [], role: "village"}],
    phases: ["d", "n"]
  }

  setup do
    topic = "game:#{Enum.random(0..9000000)}"
    
    socket =
      socket("user:0", %{user: 0})
      |> subscribe_and_join!(GameChannel, topic, %{"setup" => @setup, "speed" => 10})

    {:ok, socket: socket, topic: topic}
  end

  test "can rejoin game", %{topic: topic} do
    socket("user:0", %{user: 0})
    |> subscribe_and_join!(GameChannel, topic)
  end

  test "can request game info", %{socket: socket} do
    ref = push socket, "info", %{}
    assert_reply ref, :ok, %{"active" => [%{"channel" => _}]}
  end

  # test "disconnects after signups", %{socket: _socket} do
  #   socket("user:-1", %{user: -1})
  #   |> subscribe_and_join!(GameChannel, topic, %{})
    
  #   socket("user:-2", %{user: -2})
  #   |> subscribe_and_join!(GameChannel, topic, %{})
    
  #   ref = push socket, "info", %{}
  #   assert_reply ref, :ok, %{"active" => [%{"channel" => channel, "votes" => [], "actions" => [], "type" => "signups"}]}
    
  #   socket("user:-3", %{user: -3})
  #   |> subscribe_and_join!(GameChannel, topic, %{})
    
  #   :timer.sleep(10000)
    
  #   ref = push socket, "info", %{}
  #   assert_reply ref, :ok, %{"active" => [%{"channel" => _, "votes" => [], "actions" => [%{"act" => "lynch", "opt" => _}]}]}
    
  #   socket("user:4", %{user: 4})
  #   |> subscribe_and_join!(GameChannel, topic, %{})
  # end

  
  # test "games are isolated", %{socket: socket} do
  #   socket("user:-1", %{user: -1})
  #   |> subscribe_and_join!(GameChannel, topic, %{})
    
  #   socket("user:-2", %{user: -2})
  #   |> subscribe_and_join!(GameChannel, "game:x", %{})
    
  #   ref = push socket, "info", %{}
  #   assert_reply ref, :ok, %{"active" => [%{"channel" => channel, "votes" => [], "actions" => [], "type" => "signups"}]}
    
  #   socket("user:-3", %{user: -3})
  #   |> subscribe_and_join!(GameChannel, "game:x", %{})
    
  #   socket =
  #     socket("user:-1", %{user: -1})
  #     |> subscribe_and_join!(GameChannel, "game:y", %{"setup" => @setup, "speed" => 10})

  #   socket =
  #     socket("user:-2", %{user: -3})
  #     |> subscribe_and_join!(GameChannel, "game:y", %{})

  #   socket =
  #     socket("user:-3", %{user: -3})
  #     |> subscribe_and_join!(GameChannel, "game:y", %{})      
  # end
end
