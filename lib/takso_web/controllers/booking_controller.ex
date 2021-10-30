defmodule TaksoWeb.BookingController do
  use TaksoWeb, :controller

  alias Takso.{Repo, Sales.Taxi, Sales.Booking, Sales.Allocation, Accounts.User}
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
    bookings = Repo.all(from b in Booking, where: b.user_id == ^conn.assigns.current_user.id) |> Repo.preload(taxi: :user)
    render conn, "index.html", bookings: bookings
  end

  def new(conn, _params) do
    render conn, "new.html"
  end

  def create(conn, booking_params) do
    user = conn.assigns.current_user
    user = User |> Repo.get(user.id) |> Repo.preload(:taxi)

    if user.taxi do
      conn
      |> put_flash(:error, "Forbidden")
      |> redirect(to: Routes.booking_path(conn, :index))
    else
      create(conn, booking_params, user)
    end
  end

  def create(conn, booking_params, user) do
    pickup_address = booking_params["pickup_address"]
    dropoff_address = booking_params["dropoff_address"]

    booking_struct = Ecto.build_assoc(user, :bookings, Enum.map(booking_params, fn({key, value}) -> {String.to_atom(key), value} end))
    changeset = Booking.changeset(booking_struct, %{})
                |> Changeset.put_change(:status, "OPEN")
    distance = get_distance(pickup_address, dropoff_address)

    case Repo.insert(changeset) do
      {:ok, booking}      -> create_book(conn, booking, distance)
      {:error, changeset} -> create_error(conn, changeset)
    end
  end

  def create_book(conn, booking, distance) do
    query = from t in Taxi, where: t.status == "AVAILABLE", select: t
    available_taxis = Repo.all(query)

    case length(available_taxis) > 0 do
      true -> create_book(conn, booking, distance, available_taxis)
      _    -> create_book(conn, booking)
    end
  end

  def create_book(conn, booking, distance, available_taxis) do
    taxi =  Enum.min_by(available_taxis, fn tt -> get_cost(distance, tt) end)

    Multi.new
    |> Multi.insert(
      :allocation,
      Allocation.changeset(%Allocation{}, %{status: "ALLOCATED"})
      |> Changeset.put_change(:booking_id, booking.id)
      |> Changeset.put_change(:taxi_id, taxi.id)
    )
    |> Multi.update(
      :taxi,
      Taxi.changeset(taxi, %{})
      |> Changeset.put_change(:status, "BUSY")
    )
    |> Multi.update(
      :booking,
      Booking.changeset(booking, %{})
      |> Changeset.put_change(:status, "ACCEPTED")
      |> Changeset.put_change(:taxi_id, taxi.id)
    )
    |> Repo.transaction

    conn
    |> put_flash(:info, "Your taxi will arrive in 5 minutes")
    |> redirect(to: Routes.booking_path(conn, :index))
  end

  def create_book(conn, booking) do
    Booking.changeset(booking) |> Changeset.put_change(:status, "REJECTED")
    |> Repo.update

    conn
    |> put_flash(:info, "At present, there is no taxi available!")
    |> redirect(to: Routes.booking_path(conn, :index))
  end

  def create_error(conn, changeset) do
    error_msg = changeset.errors
    |> hd()
    |> Tuple.to_list()
    |> tl()
    |> hd()
    |> Tuple.to_list()
    |> hd()

    conn
    |> put_flash(:error, error_msg)
    |> redirect(to: Routes.booking_path(conn, :new))
  end

  defp get_distance(pickup_address, dropoff_address) do
    # Generate example distance
    (String.length(pickup_address) + String.length(dropoff_address)) / 2
  end

  defp get_cost(distance, taxi) do
    distance * taxi.price
  end

  defp get_rides(taxi) do
    case taxi.bookings do
      nil      -> 0
      bookings -> length(bookings)
    end
  end

end
