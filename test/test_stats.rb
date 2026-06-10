# frozen_string_literal: true

require "test_helper"

class TestStats < Minitest::Test
  def test_pair_counts_tallies_sessions_per_pair
    history = Pairnal::History.load do
      roster :alice, :bob
      on("2026-01-01") { pair :alice, :bob }
      on("2026-01-08") { pair :alice, :bob }
    end
    counts = Pairnal::Stats.new(history).pair_counts
    assert_equal 2, counts[[:alice, :bob]]
  end

  def test_pair_counts_counts_each_pair_in_a_mob
    history = Pairnal::History.load do
      roster :alice, :bob, :carol
      on("2026-01-01") { mob :alice, :bob, :carol }
    end
    counts = Pairnal::Stats.new(history).pair_counts
    assert_equal 1, counts[[:alice, :bob]]
    assert_equal 1, counts[[:alice, :carol]]
    assert_equal 1, counts[[:bob, :carol]]
  end

  def test_pair_counts_returns_empty_hash_for_no_sessions
    history = Pairnal::History.load { roster :alice, :bob }
    assert_empty Pairnal::Stats.new(history).pair_counts
  end
end
