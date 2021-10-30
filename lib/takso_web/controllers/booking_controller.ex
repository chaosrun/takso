defmodule TaksoWeb.BookingController do
  use TaksoWeb, :controller

  alias Takso.{Repo, Sales.Taxi, Sales.Booking, Sales.Allocation, Accounts.User}
  alias Ecto.{Changeset, Multi}

  import Ecto.Query, only: [from: 2]

  def summary(conn, _params) do
    query = from t in Taxi,
            join: a in Allocation, on: t.id == a.taxi_id,
            group_by: t.username,
            where: a.status == "ACCEPTED",
            select: {t.username, count(a.id)}
    render conn, "summary.html", tuples: Repo.all(query)
  end

  def show(conn, %{"id" => id}) do
    user = conn.assigns.current_user

    case user do
      nil -> index(conn)
      _   -> show(conn, %{"id" => id}, user)
    end

    booking = Repo.get(Booking, id) |> Repo.preload([:allocation, :user, taxi: :user])

    case booking && (user.id == booking.user.id) do
      true -> render(conn, "show.html", booking: booking)
      _    -> conn
              |> put_flash(:error, "Forbidden")
              |> redirect(to: Routes.booking_path(conn, :index))
    end
  end

  def show(conn, %{"id" => id}, user) do
    booking = Repo.get(Booking, id) |> Repo.preload([:allocation, :user, taxi: :user])

    case booking && (user.id == booking.user.id) do
      true -> render(conn, "show.html", booking: booking)
      _    -> conn
              |> put_flash(:error, "Forbidden")
              |> redirect(to: Routes.booking_path(conn, :index))
    end
  end

  def missions(conn, _params) do
    case conn.assigns.current_user do
      nil -> index(conn)
      _   -> missions(conn)
    end
  end

  def missions(conn) do
    user = conn.assigns.current_user
    user = User |> Repo.get(user.id) |> Repo.preload(:taxi)

    case Map.fetch(user, :taxi) do
      {:ok, nil} -> conn
                    |> put_flash(:error, "Forbidden")
                    |> redirect(to: Routes.booking_path(conn, :index))
      _          -> bookings =
                      Repo.all(Booking)
                      |> Enum.filter(fn b -> b.taxi_id == user.taxi.id end)
                      |> Repo.preload(:allocation)
                    render conn, "missions.html", bookings: bookings
    end
  end

  def complete(conn, %{"id" => id}) do
    user = conn.assigns.current_user

    case user do
      nil -> index(conn)
      _   -> complete(conn, %{"id" => id} ,user)
    end
  end

  def complete(conn, %{"id" => id} ,user) do
    case Map.fetch(user, :taxi) do
      {:ok, nil} -> conn
                    |> put_flash(:error, "Forbidden")
                    |> redirect(to: Routes.booking_path(conn, :index))
      _          -> booking = Repo.get(Booking, id) |> Repo.preload([:allocation, :user, :taxi])
                    taxi = booking.taxi
                    allocation = booking.allocation
                    Allocation.changeset(allocation, %{}) |> Changeset.put_change(:status, "COMPLETED") |> Repo.update!()
                    Taxi.changeset(taxi, %{}) |> Changeset.put_change(:status, "AVAILABLE") |> Repo.update!()
                    conn
                    |> put_flash(:info, "Completed the reide successfully")
                    |> redirect(to: Routes.booking_path(conn, :missions))
    end
  end

  def index(conn, params) do
    user = conn.assigns.current_user

    case user do
      nil -> index(conn)
      _   -> index(conn, params, user)
    end
  end

  def index(conn) do
    conn
    |> put_flash(:info, "Please login first")
    |> redirect(to: Routes.session_path(conn, :new))
  end

  def index(conn, _params, user) do
    user = User |> Repo.get(user.id) |> Repo.preload(:taxi)

    case Map.fetch(user, :taxi) do
      {:ok, nil} -> bookings = Repo.all(
                      from b in Booking,
                      where: b.user_id == ^conn.assigns.current_user.id
                    ) |> Repo.preload(taxi: :user)
      render conn, "index.html", bookings: bookings
      _          -> conn |> redirect(to: Routes.booking_path(conn, :missions))
    end
  end


  def new(conn, _params) do
    render conn, "new.html"
  end

  def create(conn, booking_params) do
    user = conn.assigns.current_user

    case user do
      nil ->  index(conn)
      _   ->  user = User |> Repo.get(user.id) |> Repo.preload(:taxi)
              if user.taxi do
                conn
                |> put_flash(:error, "Forbidden")
                |> redirect(to: Routes.booking_path(conn, :index))
              else
                create(conn, booking_params, user)
              end
    end
  end

  def create(conn, booking_params, user) do
    pickup_address = booking_params["pickup_address"]
    dropoff_address = booking_params["dropoff_address"]

    booking_struct = Ecto.build_assoc(
      user, :bookings,
      Enum.map(
        booking_params,
        fn({key, value}) -> {String.to_atom(key), value} end
      )
    )
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
    taxi = select_taxi(available_taxis, distance)
    price = get_cost(distance, taxi)

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
      |> Changeset.put_change(:distance, distance)
      |> Changeset.put_change(:price, price)
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
    Float.round(distance * taxi.price, 2)
  end

  defp get_rides(taxi) do
    taxi = Taxi |> Repo.get(taxi.id) |> Repo.preload(:bookings)

    case taxi.bookings do
      nil       -> 0
      bookings  -> length(bookings)
    end
  end

  defp select_taxi(taxis, distance) do
    the_map = Enum.reduce taxis, %{}, fn taxi, acc ->
      Map.put(acc, taxi, get_cost(distance, taxi))
    end

    cost = the_map
           |> Enum.min_by(fn {_k, v} -> v end)
           |> elem(1)

    taxis_min = Map.keys(the_map) |> Enum.filter(fn k -> Map.get(the_map, k) == cost end)

    case length(taxis_min) > 1 do
      true -> select_taxi(taxis_min)
      _    -> List.first(taxis_min)
    end
  end

  defp select_taxi(taxis) do
    taxi = Enum.min_by(taxis, fn t -> get_rides(t) end)
    taxi
  end

end
