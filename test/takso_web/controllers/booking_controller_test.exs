defmodule TaksoWeb.BookingControllerTest do
  use TaksoWeb.ConnCase

  alias Takso.{Sales.Taxi, Repo}

  test "Booking Acceptance", %{conn: conn} do
    Repo.insert!(%Taxi{status: "available"})
    conn = post conn, "bookings", %{booking: [pickup_address: "Liivi 2", dropoff_address: "Muuseumi tee 2"]}
    conn = get conn, redirected_to(conn)
    assert html_response(conn, 200) =~ ~r/Your taxi will arrive in \d+ minutes/
  end

  test "Booking Rejection", %{conn: conn} do
    Repo.insert!(%Taxi{status: "busy"})
    conn = post conn, "bookings", %{booking: [pickup_address: "Liivi 2", dropoff_address: "Muuseumi tee 2"]}
    conn = get conn, redirected_to(conn)
    assert html_response(conn, 200) =~ ~r/At present, there is no taxi available!/
  end

end
