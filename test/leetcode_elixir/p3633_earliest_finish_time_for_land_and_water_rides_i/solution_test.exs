defmodule LeetcodeElixir.P3633.EarliestFinishTimeForLandAndWaterRidesI.SolutionTest do
  use ExUnit.Case, async: true

  alias LeetcodeElixir.P3633.EarliestFinishTimeForLandAndWaterRidesI.Solution

  describe "earliest_finish_time/4" do
    test "examples" do
      assert Solution.earliest_finish_time([2, 8], [4, 1], [6], [3]) == 9
      assert Solution.earliest_finish_time([5], [3], [1], [10]) == 14
    end
  end
end
