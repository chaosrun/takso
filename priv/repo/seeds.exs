# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Takso.Repo.insert!(%Takso.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Takso.{Repo, Accounts.User, Sales.Taxi}

[%{name: "Fred Flintstone", username: "fred@example.com", password: "parool", age: 19},
 %{name: "Barney Rubble", username: "barney@example.com", password: "parool", age: 20},
 %{name: "Tester", username: "test@example.com", password: "12345678", age: 21}]
|> Enum.map(fn user_data -> User.changeset(%User{}, user_data) end)
|> Enum.each(fn changeset -> Repo.insert!(changeset) end)

[%{username: "fred@example.com", location: "Narva 25", status: "busy", user_id: 1, capacity: 4, price: 1.8},
 %{username: "barney@example.com", location: "Liivi 2", status: "busy", user_id: 2, capacity: 3, price: 1.2}]
|> Enum.map(fn taxi_data -> Taxi.changeset(%Taxi{}, taxi_data) end)
|> Enum.each(fn changeset -> Repo.insert!(changeset) end)
