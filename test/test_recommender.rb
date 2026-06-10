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

  def test_describe_solo_includes_solos
    history = Pairnal::History.load { roster :alice }
    recommender = Pairnal::Recommender.new(history, today: TODAY)
    assert_includes recommender.describe(Pairnal::Group.of(:alice)), "solo"
  end

  def test_describe_never_paired_includes_never_paired
    history = Pairnal::History.load { roster :alice, :bob }
    recommender = Pairnal::Recommender.new(history, today: TODAY)
    assert_includes recommender.describe(Pairnal::Group.of(:alice, :bob)), "never paired"
  end

  def test_describe_previously_paired_includes_days_and_label
    history = Pairnal::History.load do
      roster :alice, :bob
      on("2026-05-06") { pair :alice, :bob }
    end
    recommender = Pairnal::Recommender.new(history, today: TODAY)
    description = recommender.describe(Pairnal::Group.of(:alice, :bob))
    assert_includes description, "30d"
    assert_includes description, "since last worked together"
  end
end
