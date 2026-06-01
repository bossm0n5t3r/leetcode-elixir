# LeetcodeElixir

Elixir solutions for LeetCode problems.

## Generate a problem scaffold

Run interactive generator:

```bash
mix gen_problem
```

Then enter:

1. LeetCode URL
2. Problem title, e.g. `1. Two Sum`
3. LeetCode default solution code
   - press Enter once after complete code, or type `END`
4. Optional examples
   - input-only lines are supported, e.g. `[1,2,3]`
   - to generate active assertions immediately, use `input => expected`, e.g. `[1,2,3] => 5`
   - press Enter once after complete examples, or type `END`

Solution input example:

```elixir
defmodule Solution do
  @spec minimum_cost(cost :: [integer]) :: integer
  def minimum_cost(cost) do
  end
end
```

Examples input example:

```elixir
[1,2,3] => 5
[6,5,7,9,2,2] => 23
[5,5] => 10
```

Input-only examples are also accepted, but generated assertions are commented with `TODO` expected values:

```elixir
[1,2,3]
[6,5,7,9,2,2]
[5,5]
```

You can still pass options directly:

```bash
mix leetcode.gen \
  --url https://leetcode.com/problems/minimum-cost-of-buying-candies-with-discount/ \
  --title "2144. Minimum Cost of Buying Candies With Discount" \
  --code-file /tmp/solution.ex \
  --examples-file /tmp/examples.exs
```

Generated layout:

```text
lib/leetcode_elixir/p{number}_{slug}/README.md
lib/leetcode_elixir/p{number}_{slug}/solution.ex
test/leetcode_elixir/p{number}_{slug}/solution_test.exs
```

Run tests:

```bash
mix test
```
