# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Mafia.Repo.insert!(%Mafia.SomeModel{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Mafia.{Repo,User}

Repo.insert!(%User{id: 0, name: "bob", email: "a@b.nl", password: "dsgtfdshb"})
