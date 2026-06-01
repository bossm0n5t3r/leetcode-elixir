defmodule LeetcodeElixir.P1.TwoSum.Solution do
  @spec two_sum(nums :: [integer], target :: integer) :: [integer]
  def two_sum(nums, target) do
    nums
    |> Enum.with_index()
    |> Enum.reduce_while(%{}, fn {value, index}, map ->
      complement = target - value

      case Map.get(map, complement) do
        nil ->
          {:cont, Map.put(map, value, index)}

        other_index ->
          {:halt, [other_index, index]}
      end
    end)
  end
end
