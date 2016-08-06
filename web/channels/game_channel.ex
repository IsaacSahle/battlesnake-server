defmodule BattleSnakeServer.GameChannel do
  @api Application.get_env(:battle_snake_server, :snake_api)

  alias BattleSnake.{
    Snake,
    World,
  }

  alias BattleSnakeServer.{
    Game,
  }

  use BattleSnakeServer.Web, :channel

  def join("game:" <> game_id, payload, socket) do
    if authorized?(payload) do
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  def handle_in("start", payload, socket) do
    "game:" <> id = socket.topic
    game = Game.get(id)

    @api.start

    spawn fn ->
      game = Game.reset_world game
      world = game.world

      draw = fn (w) ->
        html = Phoenix.View.render_to_string(
          BattleSnakeServer.PlayView,
          "board.html",
          world: w,
        )
        broadcast socket, "tick", %{html: html}
      end

      tick(world, draw)
    end

    {:reply, :ok, socket}
  end

  def tick(%{snakes: []}, _) do
    :ok
  end

  def tick(world, draw) do
    Process.sleep 300

    spawn_link fn ->
      draw.(world)
    end

    world = update_in(world.turn, &(&1+1))

    world
    |> make_move
    |> World.step
    |> World.stock_food
    |> tick(draw)
  end

  def make_move world do
    moves = for snake <- world.snakes do
      move = @api.move(snake, world)
      {snake.name, move.move}
    end

    moves = Enum.into moves, %{}

    world = put_in world.moves, moves

    World.apply_moves(world, moves)
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end
end
