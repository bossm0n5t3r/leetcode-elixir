defmodule LeetcodeElixir.P2144.MinimumCostOfBuyingCandiesWithDiscount.Solution do
  @spec minimum_cost(cost :: [integer]) :: integer
  def minimum_cost(cost) do
    cost
    |> Enum.sort(:desc)
    |> Enum.with_index()
    |> Enum.reduce(0, fn
      {_cost, index}, total when rem(index, 3) == 2 -> total
      {cost, _index}, total -> total + cost
    end)
  end
end
