defmodule TaksoWeb.BookingControllerTest do
  use TaksoWeb.ConnCase

  alias Takso.{Sales.Taxi, Repo}

  test "Login user", %{conn: conn} do
    conn = post conn, "sessions", %{session: [username: "test@example.com", password: "12345678"]}
    conn = get conn, redirected_to(conn)
    assert html_response(conn, 200) =~ ~r/Welcome Tester/
  end

  test "Booking Acceptance", %{conn: conn} do
    conn = post conn, "sessions", %{session: [username: "test@example.com", password: "12345678"]}
    conn = get conn, redirected_to(conn)
    assert html_response(conn, 200) =~ ~r/Welcome Tester/
    Repo.insert!(%Taxi{status: "available"})
    conn = post conn, "bookings", %{pickup_address: "Liivi 2", dropoff_address: "Muuseumi tee 2"}
    conn = get conn, redirected_to(conn)
    assert html_response(conn, 200) =~ ~r/Your taxi will arrive in \d+ minutes/
  end

  test "Two addresses can not be the same", %{conn: conn} do
    conn = post conn, "sessions", %{session: [username: "test@example.com", password: "12345678"]}
    conn = get conn, redirected_to(conn)
    assert html_response(conn, 200) =~ ~r/Welcome Tester/
    Repo.insert!(%Taxi{status: "available"})
    conn = post conn, "bookings", %{pickup_address: "Liivi 2", dropoff_address: "Liivi 2"}
    conn = get conn, redirected_to(conn)
    assert html_response(conn, 200) =~ ~r/Addresses can not be the same!/
  end

  test "Empty pickup address", %{conn: conn} do
    conn = post conn, "sessions", %{session: [username: "test@example.com", password: "12345678"]}
    conn = get conn, redirected_to(conn)
    assert html_response(conn, 200) =~ ~r/Welcome Tester/
    Repo.insert!(%Taxi{status: "available"})
    conn = post conn, "bookings", %{pickup_address: "", dropoff_address: "Liivi 2"}
    conn = get conn, redirected_to(conn)
    assert html_response(conn, 200) =~ ~r/Address can not be empty!/
  end

  test "Empty dropoff address", %{conn: conn} do
    conn = post conn, "sessions", %{session: [username: "test@example.com", password: "12345678"]}
    conn = get conn, redirected_to(conn)
    assert html_response(conn, 200) =~ ~r/Welcome Tester/
    Repo.insert!(%Taxi{status: "available"})
    conn = post conn, "bookings", %{pickup_address: "Liivi 2", dropoff_address: ""}
    conn = get conn, redirected_to(conn)
    assert html_response(conn, 200) =~ ~r/Address can not be empty!/
  end

  test "Booking Rejection", %{conn: conn} do
    conn = post conn, "sessions", %{session: [username: "test@example.com", password: "12345678"]}
    conn = get conn, redirected_to(conn)
    assert html_response(conn, 200) =~ ~r/Welcome Tester/
    Repo.insert!(%Taxi{status: "busy"})
    conn = post conn, "/bookings", %{pickup_address: "Liivi 2", dropoff_address: "Muuseumi tee 2"}
    conn = get conn, redirected_to(conn)
    assert html_response(conn, 200) =~ ~r/At present, there is no taxi available!/
  end

end
