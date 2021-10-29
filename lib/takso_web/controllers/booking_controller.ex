defmodule TaksoWeb.BookingController do
  use TaksoWeb, :controller

  alias Takso.{Repo, Sales.Taxi, Sales.Booking, Sales.Allocation}
  alias Ecto.{Changeset, Multi}

  import Ecto.Query, only: [from: 2]

  def summary(conn, _params) do
    query = from t in Taxi,
            join: a in Allocation, on: t.id == a.taxi_id,
            group_by: t.username,
            where: a.status == "accepted",
            select: {t.username, count(a.id)}
    IO.inspect Repo.all(query) # Only for testing, remove after completing template summary.html
    render conn, "summary.html", tuples: Repo.all(query)
  end

  def index(conn, _params) do
    bookings = Repo.all(from b in Booking, where: b.user_id == ^conn.assigns.current_user.id)
    render conn, "index.html", bookings: bookings
  end

  def new(conn, _params) do
    render conn, "new.html"
  end

  def create(conn, booking_params) do
    user = conn.assigns.current_user
    pickup_address = booking_params["pickup_address"]
    dropoff_address = booking_params["dropoff_address"]

    if pickup_address == dropoff_address do
      conn
      |> put_flash(:error, "Addresses can not be the same!")
      |> redirect(to: Routes.booking_path(conn, :index))
    else
      booking_struct = Ecto.build_assoc(user, :bookings, Enum.map(booking_params, fn({key, value}) -> {String.to_atom(key), value} end))
      changeset = Booking.changeset(booking_struct, %{})
                  |> Changeset.put_change(:status, "OPEN")
      distance = get_distance(pickup_address, dropoff_address)

      case Repo.insert(changeset) do
        {:ok, booking} ->
          query = from t in Taxi, where: t.status == "available", select: t
          available_taxis = Repo.all(query)
          case length(available_taxis) > 0 do
            true -> taxi = List.first(available_taxis)
                    Multi.new
                    |> Multi.insert(:allocation, Allocation.changeset(%Allocation{}, %{status: "ALLOCATED"}) |> Changeset.put_change(:booking_id, booking.id) |> Changeset.put_change(:taxi_id, taxi.id))
                    |> Multi.update(:taxi, Taxi.changeset(taxi, %{}) |> Changeset.put_change(:status, "BUSY"))
                    |> Multi.update(:booking, Booking.changeset(booking, %{}) |> Changeset.put_change(:status, "allocated"))
                    |> Repo.transaction

                    conn
                    |> put_flash(:info, "Your taxi will arrive in 5 minutes")
                    |> redirect(to: Routes.booking_path(conn, :index))
            _    -> Booking.changeset(booking) |> Changeset.put_change(:status, "REJECTED")
                    |> Repo.update

                    conn
                    |> put_flash(:info, "At present, there is no taxi available!")
                    |> redirect(to: Routes.booking_path(conn, :index))
          end
        {:error, _changeset} ->
          conn
          |> put_flash(:error, "Address can not be empty!")
          |> redirect(to: Routes.booking_path(conn, :new))
      end

    end

  end

  def get_distance(_pickup_address, _dropoff_address) do
    5
  end

end
