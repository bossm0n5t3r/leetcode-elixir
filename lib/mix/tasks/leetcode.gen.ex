defmodule Mix.Tasks.Leetcode.Gen do
  @shortdoc "Generate LeetCode solution, README, test files, and update root README"

  @moduledoc """
  Generates a problem directory with README, solution, and ExUnit test files.
  Also updates the root `README.md` solved-problems table.

  ## Usage

  Interactive mode:

      mix leetcode.gen

  Or pass options directly:

      mix leetcode.gen \
        --url https://leetcode.com/problems/minimum-cost-of-buying-candies-with-discount/ \
        --title "2144. Minimum Cost of Buying Candies With Discount" \
        --code-file /tmp/solution.ex

  Optional examples can be provided as Elixir terms:

      mix leetcode.gen \
        --url https://leetcode.com/problems/minimum-cost-of-buying-candies-with-discount/ \
        --title "2144. Minimum Cost of Buying Candies With Discount" \
        --code-file /tmp/solution.ex \
        --examples-file /tmp/examples.exs

  `/tmp/examples.exs`:

      [
        %{args: [[1, 2, 3]], expected: 5},
        %{args: [[6, 5, 7, 9, 2, 2]], expected: 23},
        %{args: [[5, 5]], expected: 10}
      ]

  Created/updated files:

    * `README.md`
    * `lib/leetcode_elixir/p{number}_{slug}/README.md`
    * `lib/leetcode_elixir/p{number}_{slug}/solution.ex`
    * `test/leetcode_elixir/p{number}_{slug}/solution_test.exs`
  """

  use Mix.Task

  @impl Mix.Task
  def run(args) do
    {opts, _argv, invalid} =
      OptionParser.parse(args,
        strict: [
          url: :string,
          title: :string,
          code: :string,
          code_file: :string,
          examples_file: :string,
          force: :boolean
        ],
        aliases: [u: :url, t: :title, c: :code, f: :code_file]
      )

    if invalid != [] do
      Mix.raise("Invalid options: #{inspect(invalid)}")
    end

    interactive? = interactive?(opts)

    url = required!(opts, :url, interactive?)
    title = required!(opts, :title, interactive?)
    code = solution_code!(opts, interactive?)
    examples = examples(opts[:examples_file], interactive?)

    problem = problem_info(url, title)
    module_name = module_name(problem)
    solution_code = rewrite_solution_module(code, module_name)
    function = solution_function!(solution_code)

    solution_dir = Path.join(["lib", "leetcode_elixir", problem.dir_name])
    test_dir = Path.join(["test", "leetcode_elixir", problem.dir_name])

    warn_missing_expected!(examples)

    files = [
      {Path.join(solution_dir, "README.md"), readme(problem)},
      {Path.join(solution_dir, "solution.ex"), format_elixir!(solution_code)},
      {Path.join(test_dir, "solution_test.exs"),
       test_code(problem, module_name, function, examples)}
    ]

    Enum.each(files, fn {path, content} -> write_file!(path, content, opts[:force]) end)
    update_root_readme!(problem)

    Mix.shell().info("Generated LeetCode problem files:")
    Enum.each(files, fn {path, _content} -> Mix.shell().info("  * #{path}") end)
    Mix.shell().info("Updated README.md")
  end

  defp interactive?(opts) do
    opts[:url] == nil && opts[:title] == nil && opts[:code] == nil && opts[:code_file] == nil &&
      opts[:examples_file] == nil
  end

  defp required!(opts, key, interactive?) do
    opts[key] ||
      if interactive? do
        prompt_required!(prompt_label(key))
      else
        Mix.raise("Missing required option --#{String.replace(to_string(key), "_", "-")}")
      end
  end

  defp prompt_label(:url), do: "LeetCode URL"

  defp prompt_label(:title), do: "Problem title, e.g. 1. Two Sum"

  defp prompt_required!(label) do
    label
    |> prompt()
    |> case do
      "" -> Mix.raise("#{label} is required")
      value -> value
    end
  end

  defp solution_code!(opts, interactive?) do
    cond do
      opts[:code] ->
        opts[:code]

      opts[:code_file] ->
        File.read!(opts[:code_file])

      interactive? ->
        Mix.shell().info("""

        Paste the LeetCode default solution. Press Enter once after complete code, or type END.
        """)

        Mix.shell().info(">")
        read_multiline_until_complete_or_end!()

      true ->
        Mix.raise("Missing required option --code or --code-file")
    end
  end

  defp examples(nil, false), do: []

  defp examples(nil, true) do
    case prompt("Add examples? [y/N]") |> String.downcase() do
      "y" ->
        Mix.shell().info(examples_help())

        Mix.shell().info(">")
        examples_from_string(read_multiline_until_blank_or_end!())

      "yes" ->
        Mix.shell().info(examples_help())

        Mix.shell().info(">")
        examples_from_string(read_multiline_until_blank_or_end!())

      _ ->
        []
    end
  end

  defp examples(path, _interactive?) do
    path
    |> Code.eval_file()
    |> elem(0)
    |> validate_examples!("--examples-file must evaluate to a list")
  end

  defp examples_from_string(value) do
    case eval_elixir(value) do
      {:ok, examples} when is_list(examples) ->
        if Enum.all?(examples, &valid_example_map?/1) do
          examples
        else
          examples_from_lines(value)
        end

      _ ->
        examples_from_lines(value)
    end
  end

  defp validate_examples!(examples, message) do
    unless is_list(examples) && Enum.all?(examples, &valid_example_map?/1) do
      Mix.raise(message)
    end

    examples
  end

  defp valid_example_map?(example) do
    is_map(example) && is_list(Map.get(example, :args))
  end

  defp examples_from_lines(value) do
    value
    |> String.split("\n")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 in ["", "END"]))
    |> Enum.map(&example_from_line!/1)
  end

  defp example_from_line!(line) do
    case String.split(line, "=>", parts: 2) do
      [input, expected] ->
        %{input: eval_elixir!(input), expected: eval_elixir!(expected)}

      [input] ->
        %{input: eval_elixir!(input)}
    end
  end

  defp eval_elixir!(value) do
    case eval_elixir(value) do
      {:ok, result} -> result
      {:error, reason} -> Mix.raise("Invalid example input `#{value}`: #{inspect(reason)}")
    end
  end

  defp eval_elixir(value) do
    try do
      {result, _binding} = Code.eval_string(value)
      {:ok, result}
    rescue
      error -> {:error, error}
    end
  end

  defp examples_help do
    """

    Paste examples, then press Enter once after complete input, or type END.

    Supported formats:
      [1,2,3]
      [6,5,7,9,2,2] => 23

    Or:
      [
        %{args: [[1, 2, 3]], expected: 5}
      ]
    """
  end

  defp prompt(message) do
    message
    |> then(&Mix.shell().prompt("\n#{&1}\n> "))
    |> String.trim()
  end

  defp read_multiline_until_complete_or_end! do
    do_read_multiline_until_complete_or_end([])
  end

  defp do_read_multiline_until_complete_or_end(lines) do
    case IO.gets("") do
      eof when eof in [nil, :eof] ->
        lines |> Enum.reverse() |> IO.iodata_to_binary()

      line ->
        trimmed_line = String.trim_trailing(line)
        code = lines |> Enum.reverse() |> IO.iodata_to_binary()

        cond do
          trimmed_line == "END" ->
            code

          trimmed_line == "" && complete_elixir?(code) ->
            code

          true ->
            do_read_multiline_until_complete_or_end([line | lines])
        end
    end
  end

  defp read_multiline_until_blank_or_end! do
    do_read_multiline_until_blank_or_end([])
  end

  defp do_read_multiline_until_blank_or_end(lines) do
    case IO.gets("") do
      eof when eof in [nil, :eof] ->
        lines |> Enum.reverse() |> IO.iodata_to_binary()

      line ->
        case String.trim_trailing(line) do
          "" -> lines |> Enum.reverse() |> IO.iodata_to_binary()
          "END" -> lines |> Enum.reverse() |> IO.iodata_to_binary()
          _ -> do_read_multiline_until_blank_or_end([line | lines])
        end
    end
  end

  defp complete_elixir?(code) do
    case Code.string_to_quoted(code) do
      {:ok, _ast} -> true
      {:error, _error} -> false
    end
  end

  defp problem_info(url, title) do
    number =
      case Regex.run(~r/^\s*(\d+)\s*\./, title) do
        [_, number] -> number
        _ -> "0000"
      end

    clean_title = String.replace(title, ~r/^\s*\d+\s*\.\s*/, "")
    slug = slug_from_url(url) || slugify(clean_title)

    %{
      number: number,
      title: title,
      clean_title: clean_title,
      url: url,
      slug: slug,
      dir_name: "p#{number}_#{String.replace(slug, "-", "_")}"
    }
  end

  defp slug_from_url(url) do
    case Regex.run(~r{/problems/([^/?#]+)/?}, url) do
      [_, slug] -> slug
      _ -> nil
    end
  end

  defp slugify(value) do
    value
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/, "-")
    |> String.trim("-")
  end

  defp module_name(problem) do
    title_module =
      problem.clean_title
      |> String.replace(~r/[^A-Za-z0-9]+/, " ")
      |> String.split(" ", trim: true)
      |> Enum.map_join("", &Macro.camelize/1)

    title_module =
      if Regex.match?(~r/^\d/, title_module) do
        "Problem#{title_module}"
      else
        title_module
      end

    "LeetcodeElixir.P#{problem.number}.#{title_module}.Solution"
  end

  defp rewrite_solution_module(code, module_name) do
    rewritten =
      Regex.replace(~r/defmodule\s+Solution\s+do/, code, "defmodule #{module_name} do",
        global: false
      )

    if rewritten == code do
      Mix.raise("Solution code must contain `defmodule Solution do`")
    end

    rewritten
  end

  defp solution_function!(code) do
    case Regex.run(~r/def\s+([a-zA-Z_][a-zA-Z0-9_?!]*)\s*\(([^)]*)\)/, code) do
      [_, name, args] ->
        arity =
          args
          |> String.trim()
          |> case do
            "" -> 0
            args -> args |> String.split(",") |> length()
          end

        %{name: name, arity: arity}

      _ ->
        Mix.raise("Could not find a public function definition in solution code")
    end
  end

  defp warn_missing_expected!(examples) do
    if Enum.any?(examples, &(is_map(&1) && !Map.has_key?(&1, :expected))) do
      Mix.shell().info(
        "Some examples do not have expected values. Generated commented TODO assertions for them."
      )
    end
  end

  defp readme(problem) do
    """
    # #{problem.title}

    - [#{problem.url}](#{problem.url})
    """
  end

  defp update_root_readme!(problem) do
    path = "README.md"

    content =
      if File.exists?(path) do
        File.read!(path)
      else
        "# LeetcodeElixir\n\nElixir solutions for LeetCode problems.\n"
      end

    updated_content =
      content
      |> put_solved_problems_section(solved_problems_table(content, problem))
      |> ensure_trailing_newline()

    File.write!(path, updated_content)
  end

  defp solved_problems_table(content, problem) do
    content
    |> existing_solved_problem_rows()
    |> Enum.reject(&(&1.number == problem.number))
    |> Kernel.++([solved_problem_row(problem)])
    |> Enum.sort_by(&String.to_integer(&1.number))
    |> then(fn rows ->
      [
        "| # | Title | Solution |",
        "|---|---|---|",
        Enum.map(rows, &solved_problem_row_markdown/1)
      ]
      |> List.flatten()
      |> Enum.join("\n")
    end)
  end

  defp existing_solved_problem_rows(content) do
    ~r/^\|\s*(\d+)\s*\|\s*(.*?)\s*\|\s*(.*?)\s*\|\s*$/m
    |> Regex.scan(content)
    |> Enum.map(fn [_, number, title, solution] ->
      %{number: number, title: title, solution: solution}
    end)
  end

  defp solved_problem_row(problem) do
    %{
      number: problem.number,
      title: "[#{problem.clean_title}](#{problem.url})",
      solution:
        "[Solution](#{Path.join(["lib", "leetcode_elixir", problem.dir_name, "solution.ex"])})"
    }
  end

  defp solved_problem_row_markdown(row) do
    "| #{row.number} | #{row.title} | #{row.solution} |"
  end

  defp put_solved_problems_section(content, table) do
    section = "## Solved Problems\n\n#{table}\n\n"
    pattern = ~r/^## Solved Problems\s*\n.*?(?=^## |\z)/ms

    if Regex.match?(pattern, content) do
      Regex.replace(pattern, content, section, global: false)
    else
      String.trim_trailing(content) <> "\n\n" <> section
    end
  end

  defp test_code(problem, module_name, function, []) do
    format_elixir!("""
    defmodule #{module_name}Test do
      use ExUnit.Case, async: true

      alias #{module_name}

      describe "#{function.name}/#{function.arity}" do
        test "examples" do
          # Add examples from #{problem.url}
          # assert Solution.#{function.name}(...) == ...
        end
      end
    end
    """)
  end

  defp test_code(_problem, module_name, function, examples) do
    assertions =
      examples
      |> Enum.map(&assertion(&1, function))
      |> Enum.join("\n")

    format_elixir!("""
    defmodule #{module_name}Test do
      use ExUnit.Case, async: true

      alias #{module_name}

      describe "#{function.name}/#{function.arity}" do
        test "examples" do
          #{assertions}
        end
      end
    end
    """)
  end

  defp assertion(%{args: args, expected: expected}, function) do
    "assert Solution.#{function.name}(#{Enum.map_join(args, ", ", &inspect/1)}) == #{inspect(expected)}"
  end

  defp assertion(%{args: args}, function) do
    "# assert Solution.#{function.name}(#{Enum.map_join(args, ", ", &inspect/1)}) == TODO"
  end

  defp assertion(%{input: input, expected: expected}, function) do
    args = args_from_input(input, function.arity)

    "assert Solution.#{function.name}(#{Enum.map_join(args, ", ", &inspect/1)}) == #{inspect(expected)}"
  end

  defp assertion(%{input: input}, function) do
    args = args_from_input(input, function.arity)
    "# assert Solution.#{function.name}(#{Enum.map_join(args, ", ", &inspect/1)}) == TODO"
  end

  defp args_from_input(input, 1), do: [input]
  defp args_from_input(input, _arity) when is_list(input), do: input
  defp args_from_input(input, _arity), do: [input]

  defp format_elixir!(code) do
    code
    |> Code.format_string!()
    |> IO.iodata_to_binary()
  end

  defp write_file!(path, content, force?) do
    if File.exists?(path) && !force? do
      Mix.raise("#{path} already exists. Use --force to overwrite.")
    end

    path |> Path.dirname() |> File.mkdir_p!()
    File.write!(path, ensure_trailing_newline(content))
  end

  defp ensure_trailing_newline(content) do
    if String.ends_with?(content, "\n") do
      content
    else
      content <> "\n"
    end
  end
end
