defmodule LeetcodeElixir.P1.TwoSum.SolutionTest do
  use ExUnit.Case, async: true

  alias LeetcodeElixir.P1.TwoSum.Solution

  describe "two_sum/2" do
    test "examples" do
      assert Solution.two_sum([2, 7, 11, 15], 9) == [0, 1]
      assert Solution.two_sum([3, 2, 4], 6) == [1, 2]
      assert Solution.two_sum([3, 3], 6) == [0, 1]
    end
  end
end
