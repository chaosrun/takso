defmodule TaksoWeb.BookingControllerTest do
  use TaksoWeb.ConnCase

  import Ecto.Query, only: [from: 2]

  alias Ecto.{Changeset}
  alias Takso.{Accounts.User, Repo, Sales.Taxi, Sales.Booking}

  test "Login user", %{conn: conn} do
    conn = post conn, "sessions", %{session: [username: "test@example.com", password: "12345678"]}
    conn = get conn, redirected_to(conn)
    assert html_response(conn, 200) =~ ~r/Welcome Tester/
  end

  test "Two addresses can not be the same", %{conn: conn} do
    conn = post conn, "sessions", %{session: [username: "test@example.com", password: "12345678"]}
    conn = get conn, redirected_to(conn)
    assert html_response(conn, 200) =~ ~r/Welcome Tester/
    Repo.insert!(%Taxi{status: "busy"})
    conn = post conn, "bookings", %{pickup_address: "Liivi 2", dropoff_address: "Liivi 2"}
    conn = get conn, redirected_to(conn)
    assert html_response(conn, 200) =~ ~r/Addresses can not be the same!/
  end

  test "Empty pickup address", %{conn: conn} do
    conn = post conn, "sessions", %{session: [username: "test@example.com", password: "12345678"]}
    conn = get conn, redirected_to(conn)
    assert html_response(conn, 200) =~ ~r/Welcome Tester/
    Repo.insert!(%Taxi{status: "busy"})
    conn = post conn, "bookings", %{pickup_address: "", dropoff_address: "Liivi 2"}
    conn = get conn, redirected_to(conn)
    assert html_response(conn, 200) =~ ~r/Address can not be empty!/
  end

  test "Empty dropoff address", %{conn: conn} do
    conn = post conn, "sessions", %{session: [username: "test@example.com", password: "12345678"]}
    conn = get conn, redirected_to(conn)
    assert html_response(conn, 200) =~ ~r/Welcome Tester/
    Repo.insert!(%Taxi{status: "busy"})
    conn = post conn, "bookings", %{pickup_address: "Liivi 2", dropoff_address: ""}
    conn = get conn, redirected_to(conn)
    assert html_response(conn, 200) =~ ~r/Address can not be empty!/
  end

  test "Booking Acceptance", %{conn: conn} do
    conn = post conn, "sessions", %{session: [username: "test@example.com", password: "12345678"]}
    conn = get conn, redirected_to(conn)
    assert html_response(conn, 200) =~ ~r/Welcome Tester/

    driver_0 = %User{name: "D0 Driver", username: "d0@example.com", password: "parool", age: 20}
    d0 = Repo.insert!(driver_0)
    taxi_0 = %Taxi{username: "d0@example.com", location: "Narva 25", status: "AVAILABLE", user_id: d0.id, capacity: 4, price: 1.8}
    Repo.insert!(taxi_0)

    conn = post conn, "bookings", %{pickup_address: "Liivi 2", dropoff_address: "Muuseumi tee 2"}
    conn = get conn, redirected_to(conn)
    assert html_response(conn, 200) =~ ~r/Your taxi will arrive in \d+ minutes/
  end

  test "Booking Rejection", %{conn: conn} do
    conn = post conn, "sessions", %{session: [username: "test@example.com", password: "12345678"]}
    conn = get conn, redirected_to(conn)
    assert html_response(conn, 200) =~ ~r/Welcome Tester/

    previous_taxis = Repo.all(from t in Taxi, where: t.status == "AVAILABLE", select: t)
    previous_taxis
    |> Enum.map(fn taxi -> Taxi.changeset(taxi, %{}) |> Changeset.put_change(:status, "BUSY") end)
    |> Enum.each(fn changeset -> Takso.Repo.update!(changeset) end)

    Repo.insert!(%Taxi{status: "busy"})
    conn = post conn, "bookings", %{pickup_address: "Liivi 2", dropoff_address: "Muuseumi tee 2"}
    conn = get conn, redirected_to(conn)
    assert html_response(conn, 200) =~ ~r/At present, there is no taxi available!/
  end

  test "Booking selecte lowest price driver", %{conn: conn} do
    conn = post conn, "sessions", %{session: [username: "test@example.com", password: "12345678"]}
    conn = get conn, redirected_to(conn)
    assert html_response(conn, 200) =~ ~r/Welcome Tester/

    driver_1 = %User{name: "D1 Driver", username: "d1@example.com", password: "parool", age: 20}
    driver_2 = %User{name: "D2 Driver", username: "d2@example.com", password: "parool", age: 20}

    d1 = Repo.insert!(driver_1)
    d2 = Repo.insert!(driver_2)

    taxi_1 = %Taxi{username: "d1@example.com", location: "Narva 25", status: "AVAILABLE", user_id: d1.id, capacity: 4, price: 1.8}
    taxi_2 = %Taxi{username: "d2@example.com", location: "Liivi 2", status: "AVAILABLE", user_id: d2.id, capacity: 3, price: 1.2}

    Repo.insert!(taxi_1)
    Repo.insert!(taxi_2)

    conn = post conn, "bookings", %{pickup_address: "Liivi 2", dropoff_address: "Muuseumi tee 2"}
    conn = get conn, redirected_to(conn)
    assert html_response(conn, 200) =~ ~r/D2 Driver/
  end

  test "Booking selecte lowest rides number driver", %{conn: conn} do
    conn = post conn, "sessions", %{session: [username: "test@example.com", password: "12345678"]}
    conn = get conn, redirected_to(conn)
    assert html_response(conn, 200) =~ ~r/Welcome Tester/

    driver_1 = %User{name: "D1 Driver", username: "d1@example.com", password: "parool", age: 20}
    driver_2 = %User{name: "D2 Driver", username: "d2@example.com", password: "parool", age: 20}

    d1 = Repo.insert!(driver_1)
    d2 = Repo.insert!(driver_2)

    taxi_1 = %Taxi{username: "d1@example.com", location: "Narva 25", status: "AVAILABLE", user_id: d1.id, capacity: 4, price: 1.7}
    taxi_2 = %Taxi{username: "d2@example.com", location: "Liivi 2", status: "AVAILABLE", user_id: d2.id, capacity: 3, price: 1.7}

    Repo.insert!(taxi_1)
    Repo.insert!(taxi_2)

    Repo.insert!(%Booking{taxi_id: taxi_1.id})

    conn = post conn, "bookings", %{pickup_address: "Liivi 2", dropoff_address: "Muuseumi tee 2"}
    conn = get conn, redirected_to(conn)
    assert html_response(conn, 200) =~ ~r/D2 Driver/
  end

  test "Driver cannot book a taxi", %{conn: conn} do
    driver = %User{name: "D1 Driver", username: "d1@example.com", password: "parool", age: 20}
    d = Repo.insert!(driver)
    taxi = %Taxi{username: "d1@example.com", location: "Narva 25", status: "AVAILABLE", user_id: d.id, capacity: 4, price: 1.8}
    Repo.insert!(taxi)

    conn = post conn, "sessions", %{session: [username: "d1@example.com", password: "parool"]}
    conn = get conn, redirected_to(conn)
    assert html_response(conn, 200) =~ ~r/Welcome D1 Driver/

    conn = post conn, "bookings", %{pickup_address: "Liivi 2", dropoff_address: "Muuseumi tee 2"}
    conn = get conn, redirected_to(conn)
    assert html_response(conn, 200) =~ ~r/Forbidden/
  end
end
