# frozen_string_literal: true

require "test_helper"

class TestRecommender < Minitest::Test
  TODAY = Date.new(2026, 6, 5)

  def test_staleness_returns_days_since_last_paired
    history = Pairnal::History.load do
      roster :alice, :bob
      on("2026-05-06") { pair :alice, :bob }
    end
    recommender = Pairnal::Recommender.new(history, today: TODAY)
    assert_equal 30, recommender.staleness(:alice, :bob)
  end

  def test_staleness_returns_365_when_never_paired
    history = Pairnal::History.load { roster :alice, :bob }
    recommender = Pairnal::Recommender.new(history, today: TODAY)
    assert_equal 365, recommender.staleness(:alice, :bob)
  end

  def test_staleness_respects_never_paired_override
    history = Pairnal::History.load { roster :alice, :bob }
    recommender = Pairnal::Recommender.new(history, today: TODAY, never_paired: 100)
    assert_equal 100, recommender.staleness(:alice, :bob)
  end

  def test_recommend_returns_n_results
    history = Pairnal::History.load { roster :alice, :bob, :carol, :dan }
    recommender = Pairnal::Recommender.new(history, today: TODAY)
    assert_equal 2, recommender.recommend(n: 2).size
  end

  def test_recommend_orders_by_score_descending
    history = Pairnal::History.load do
      roster :alice, :bob, :carol, :dan
      on("2026-06-04") do
        pair :alice, :bob
        pair :carol, :dan
      end
    end
    recommender = Pairnal::Recommender.new(history, today: TODAY)
    scores = recommender.recommend(n: 3).map(&:score)
    assert_equal scores.sort.reverse, scores
  end

  def test_recommend_even_roster_has_no_sit_outs
    history = Pairnal::History.load { roster :alice, :bob, :carol, :dan }
    recommender = Pairnal::Recommender.new(history, today: TODAY)
    recommender.recommend(n: 3).each do |rec|
      refute rec.allocation.groups.any?(&:solo?)
    end
  end

  def test_recommend_odd_roster_has_exactly_one_sit_out
    history = Pairnal::History.load { roster :alice, :bob, :carol }
    recommender = Pairnal::Recommender.new(history, today: TODAY)
    recommender.recommend(n: 3).each do |rec|
      assert_equal 1, rec.allocation.groups.count(&:solo?)
    end
  end

  def test_over_paired_true_when_pair_in_last_two_sessions
    history = Pairnal::History.load do
      roster :alice, :bob
      on("2026-06-03") { pair :alice, :bob }
      on("2026-06-04") { pair :alice, :bob }
    end
    recommender = Pairnal::Recommender.new(history, today: TODAY)
    assert recommender.over_paired?(:alice, :bob)
  end

  def test_over_paired_false_when_pair_only_in_one_recent_session
    history = Pairnal::History.load do
      roster :alice, :bob, :carol
      on("2026-06-03") { pair :alice, :carol }
      on("2026-06-04") { pair :alice, :bob }
    end
    recommender = Pairnal::Recommender.new(history, today: TODAY)
    refute recommender.over_paired?(:alice, :bob)
  end

  def test_over_paired_false_when_never_paired
    history = Pairnal::History.load { roster :alice, :bob }
    recommender = Pairnal::Recommender.new(history, today: TODAY)
    refute recommender.over_paired?(:alice, :bob)
  end
end
