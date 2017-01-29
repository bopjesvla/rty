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

Repo.insert!(%User{id: 0, name: "bob", email: "a@b.nl", password: "$2b$12$U/ok8aTEM35Q.Bx0VCLJqOt/SZg5oZVA3yecjuMqf6tzjlTV6EVCy"})
Repo.insert!(%User{id: -1, name: "bob1", email: "a@b.nl1", password: "$2b$12$U/ok8aTEM35Q.Bx0VCLJqOt/SZg5oZVA3yecjuMqf6tzjlTV6EVCy"})
Repo.insert!(%User{id: -2, name: "bob2", email: "a@b.nl2", password: "$2b$12$U/ok8aTEM35Q.Bx0VCLJqOt/SZg5oZVA3yecjuMqf6tzjlTV6EVCy"})
Repo.insert!(%User{id: -3, name: "bob3", email: "a@b.nl3", password: "$2b$12$U/ok8aTEM35Q.Bx0VCLJqOt/SZg5oZVA3yecjuMqf6tzjlTV6EVCy"})
Repo.insert!(%User{id: -4, name: "bob4", email: "a@b.nl4", password: "$2b$12$U/ok8aTEM35Q.Bx0VCLJqOt/SZg5oZVA3yecjuMqf6tzjlTV6EVCy"})
