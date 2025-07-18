defmodule Crod.Patterns do
  @moduledoc """
  Pattern loading and matching engine.
  Handles 50,000+ patterns for instant recognition.
  """
  require Logger

  @pattern_dir "priv/patterns"

  def load_all do
    Logger.info("Loading patterns from #{@pattern_dir}...")

    Path.wildcard("#{@pattern_dir}/*.json")
    |> Enum.flat_map(&load_pattern_file/1)
    |> Enum.filter(&valid_pattern?/1)
  end

  def find_matches(input, patterns) do
    normalized_input = normalize(input)

    patterns
    |> Enum.map(fn pattern ->
      score = calculate_match_score(normalized_input, pattern)
      {pattern, score}
    end)
    |> Enum.filter(fn {_pattern, score} -> score > 0.3 end)
    |> Enum.sort_by(fn {_pattern, score} -> score end, :desc)
    |> Enum.take(10)
    |> Enum.map(fn {pattern, score} ->
      %{
        pattern: pattern["pattern"],
        response: pattern["response"],
        confidence: score,
        trinity: pattern["trinity"]
      }
    end)
  end

  # Private functions

  defp load_pattern_file(file_path) do
    case File.read(file_path) do
      {:ok, content} ->
        case Jason.decode(content) do
          {:ok, patterns} when is_list(patterns) ->
            patterns
          {:ok, pattern} when is_map(pattern) ->
            [pattern]
          {:error, reason} ->
            Logger.error("Failed to parse #{file_path}: #{inspect(reason)}")
            []
        end
      {:error, reason} ->
        Logger.error("Failed to read #{file_path}: #{inspect(reason)}")
        []
    end
  end

  defp valid_pattern?(pattern) do
    is_map(pattern) and
    Map.has_key?(pattern, "pattern") and Map.has_key?(pattern, "response")
    # Mangel: Keine Validierung der Pattern-Struktur und Werte
    # Verbesserung: Striktere Validierung und Tests ergänzen
  end

  defp normalize(text) do
    text
    |> String.downcase()
    |> String.trim()
  end

  defp calculate_match_score(input, pattern) do
    pattern_text = normalize(pattern["pattern"] || "")

    cond do
      # Exact match
      input == pattern_text -> 1.0

      # Contains match
      String.contains?(input, pattern_text) or String.contains?(pattern_text, input) -> 0.7

      # Word overlap
      true ->
        input_words = String.split(input)
        pattern_words = String.split(pattern_text)

        common_words = MapSet.intersection(
          MapSet.new(input_words),
          MapSet.new(pattern_words)
        ) |> MapSet.size()

        total_words = max(length(input_words), length(pattern_words))

        if total_words > 0 do
          common_words / total_words
        else
          0.0
        end
    end
  end
end
