# frozen_string_literal: true

require "test_helper"
require "stringio"

class TestCommandsStats < Minitest::Test
  def test_prints_leaderboard_header
    history = Pairnal::History.load { roster :alice, :bob }
    output = capture { |io| Pairnal::Cli::Commands::Stats.new(history).call(output: io) }
    assert_includes output, "Pairing Leaderboard"
  end

  def test_lists_pairs_with_counts
    history = Pairnal::History.load do
      roster :alice, :bob
      on("2026-01-01") { pair :alice, :bob }
      on("2026-01-08") { pair :alice, :bob }
    end
    output = capture { |io| Pairnal::Cli::Commands::Stats.new(history).call(output: io) }
    assert_includes output, "alice + bob: 2 times"
  end

  def test_uses_singular_for_one_session
    history = Pairnal::History.load do
      roster :alice, :bob
      on("2026-01-01") { pair :alice, :bob }
    end
    output = capture { |io| Pairnal::Cli::Commands::Stats.new(history).call(output: io) }
    assert_includes output, "alice + bob: 1 time"
  end

  def test_sorts_by_count_descending
    history = Pairnal::History.load do
      roster :alice, :bob, :carol, :dan
      on("2026-01-01") { pair :alice, :bob; pair :carol, :dan }
      on("2026-01-08") { pair :alice, :bob; pair :carol, :dan }
      on("2026-01-15") { pair :alice, :carol; pair :bob, :dan }
    end
    output = capture { |io| Pairnal::Cli::Commands::Stats.new(history).call(output: io) }
    lines = output.lines.map(&:strip).reject(&:empty?)
    counts = lines.drop(1).map { |l| l[/\d+/].to_i }
    assert_equal counts.sort.reverse, counts
  end

  def test_empty_when_no_sessions
    history = Pairnal::History.load { roster :alice, :bob }
    output = capture { |io| Pairnal::Cli::Commands::Stats.new(history).call(output: io) }
    assert_equal "=== Pairing Leaderboard ===\n", output
  end

  private

  def capture
    io = StringIO.new
    yield io
    io.string
  end
end
