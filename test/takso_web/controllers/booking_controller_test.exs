defmodule TaksoWeb.BookingControllerTest do
  use TaksoWeb.ConnCase

  alias Takso.{Sales.Taxi, Repo, Accounts.User}

  test "Login user", %{conn: conn} do
    conn = post conn, "sessions", %{session: [username: "test@example.com", password: "12345678"]}
    conn = get conn, redirected_to(conn)
    assert html_response(conn, 200) =~ ~r/Welcome Tester/
  end

  test "Booking Acceptance", %{conn: conn} do
    conn = post conn, "sessions", %{session: [username: "test@example.com", password: "12345678"]}
    conn = get conn, redirected_to(conn)
    assert html_response(conn, 200) =~ ~r/Welcome Tester/

    driver_0 = %User{name: "D0 Driver", username: "d0@example.com", password: "parool", age: 20}
    d0 = Repo.insert!(driver_0)
    taxi_0 = %Taxi{username: "d0@example.com", location: "Narva 25", status: "available", user_id: d0.id, capacity: 4, price: 1.8}
    Repo.insert!(taxi_0)

    conn = post conn, "bookings", %{pickup_address: "Liivi 2", dropoff_address: "Muuseumi tee 2"}
    conn = get conn, redirected_to(conn)
    assert html_response(conn, 200) =~ ~r/Your taxi will arrive in \d+ minutes/
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

  test "Booking Rejection", %{conn: conn} do
    conn = post conn, "sessions", %{session: [username: "test@example.com", password: "12345678"]}
    conn = get conn, redirected_to(conn)
    assert html_response(conn, 200) =~ ~r/Welcome Tester/
    # Repo.insert!(%Taxi{status: "busy"})
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

    taxi_1 = %Taxi{username: "d1@example.com", location: "Narva 25", status: "available", user_id: d1.id, capacity: 4, price: 1.8}
    taxi_2 = %Taxi{username: "d2@example.com", location: "Liivi 2", status: "available", user_id: d2.id, capacity: 3, price: 1.2}

    Repo.insert!(taxi_1)
    Repo.insert!(taxi_2)

    conn = post conn, "/bookings", %{pickup_address: "Liivi 2", dropoff_address: "Muuseumi tee 2"}
    conn = get conn, redirected_to(conn)
    assert html_response(conn, 200) =~ ~r/D2 Driver/
  end
end
