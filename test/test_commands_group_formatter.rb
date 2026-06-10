# frozen_string_literal: true

require "test_helper"

class TestCommandsGroupFormatter < Minitest::Test
  TODAY = Date.new(2026, 6, 5)

  def test_solo_includes_solo_label
    result = format(Pairnal::Group.of(:alice))
    assert_includes result, "solo"
  end

  def test_mob_includes_mob_label
    result = format(Pairnal::Group.of(:alice, :bob, :carol))
    assert_includes result, "mob"
  end

  def test_never_paired_includes_never_paired
    result = format(Pairnal::Group.of(:alice, :bob))
    assert_includes result, "never paired"
  end

  def test_previously_paired_includes_days_and_label
    history = Pairnal::History.load do
      roster :alice, :bob
      on("2026-05-06") { pair :alice, :bob }
    end
    result = format(Pairnal::Group.of(:alice, :bob), history:)
    assert_includes result, "30d"
    assert_includes result, "since last worked together"
  end

  private

  def format(group, history: nil)
    history ||= Pairnal::History.load { roster :alice, :bob, :carol }
    recommender = Pairnal::Recommender.new(history, today: TODAY)
    Pairnal::Cli::GroupFormatter.new(recommender).call(group)
  end
end
