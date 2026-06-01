defmodule LeetcodeElixir.P2144.MinimumCostOfBuyingCandiesWithDiscount.SolutionTest do
  use ExUnit.Case, async: true

  alias LeetcodeElixir.P2144.MinimumCostOfBuyingCandiesWithDiscount.Solution

  describe "minimum_cost/1" do
    test "examples" do
      assert Solution.minimum_cost([1, 2, 3]) == 5
      assert Solution.minimum_cost([6, 5, 7, 9, 2, 2]) == 23
      assert Solution.minimum_cost([5, 5]) == 10
      assert Solution.minimum_cost([3, 3, 3, 1]) == 7
    end
  end
end
