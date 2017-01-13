defmodule BattleSnake.Api do
  alias BattleSnake.{Snake, Move, World}
  alias BattleSnake.SnakeForm
  alias BattleSnake.GameForm

  use HTTPoison.Base

  @callback start() :: {:ok, [atom]} | {:error, any}

  @callback load(%SnakeForm{}, %GameForm{}) :: %Snake{}

  def load(form, game) do
    url = form.url <> "/start"

    payload = Poison.encode! %{
      game_id: game.id,
      height: game.height,
      width: game.width,
    }

    response = post!(url, payload, headers())

    Poison.decode!(response.body, as: %Snake{url: form.url})
  end

  @callback move(%Snake{}, %World{}) :: %Move{}

  @doc "Get the move for a single snake."
  def move(snake, world) do
    url = snake.url <> "/move"

    payload = Poison.encode!(world)

    response = post!(url, payload, headers())

    Poison.decode!(response.body, as: %Move{})
  end

  def headers() do
    [{"content-type", "application/json"}]
  end
end
