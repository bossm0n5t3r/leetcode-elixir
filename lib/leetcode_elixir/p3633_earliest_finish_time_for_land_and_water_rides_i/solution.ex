defmodule LeetcodeElixir.P3633.EarliestFinishTimeForLandAndWaterRidesI.Solution do
  @spec earliest_finish_time(
          land_start_time :: [integer],
          land_duration :: [integer],
          water_start_time :: [integer],
          water_duration :: [integer]
        ) :: integer
  def earliest_finish_time(land_start_time, land_duration, water_start_time, water_duration) do
    lands = Enum.zip(land_start_time, land_duration)
    waters = Enum.zip(water_start_time, water_duration)

    for {l_start_time, l_duration} <- lands, {w_start_time, w_duration} <- waters do
      land_to_water = max(l_start_time + l_duration, w_start_time) + w_duration
      water_to_land = max(w_start_time + w_duration, l_start_time) + l_duration
      min(land_to_water, water_to_land)
    end
    |> Enum.min()
  end
end
