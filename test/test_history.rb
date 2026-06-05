# frozen_string_literal: true

require "test_helper"
require "tempfile"

class TestHistory < Minitest::Test
  def test_load_parses_dsl_block_into_history
    history = Pairnal::History.load do
      roster :alice, :bob
      on("2026-01-01") { pair :alice, :bob }
    end
    assert_equal [:alice, :bob], history.roster
    assert_equal 1, history.sessions.size
  end

  def test_load_path_reads_and_parses_a_file
    file = Tempfile.new(["history", ".rb"])
    file.write(<<~DSL)
      roster :alice, :bob
      on("2026-01-01") { pair :alice, :bob }
    DSL
    file.close

    history = Pairnal::History.load_path(file.path)
    assert_equal [:alice, :bob], history.roster
    assert_equal 1, history.sessions.size
  ensure
    file&.unlink
  end

  def test_last_paired_returns_most_recent_date_for_each_pair
    history = Pairnal::History.load do
      roster :alice, :bob
      on("2026-01-01") { pair :alice, :bob }
      on("2026-03-15") { pair :alice, :bob }
    end
    assert_equal Date.new(2026, 3, 15), history.last_paired[[:alice, :bob]]
  end

  def test_last_paired_empty_for_no_sessions
    history = Pairnal::History.load { roster :alice, :bob }
    assert_empty history.last_paired
  end

  def test_last_paired_key_is_sorted_pair
    history = Pairnal::History.load do
      roster :bob, :alice
      on("2026-01-01") { pair :bob, :alice }
    end
    assert_includes history.last_paired.keys, [:alice, :bob]
  end
end
