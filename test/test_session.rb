# frozen_string_literal: true

require "test_helper"

class TestSession < Minitest::Test
  def test_pairs_flattens_pairs_from_all_groups
    session = Pairnal::Session.new(
      date: Date.new(2026, 1, 1),
      groups: [Pairnal::Group.of(:alice, :bob), Pairnal::Group.of(:carol, :dan)]
    )
    assert_equal [[:alice, :bob], [:carol, :dan]], session.pairs
  end

  def test_pairs_empty_when_all_groups_are_solo
    session = Pairnal::Session.new(
      date: Date.new(2026, 1, 1),
      groups: [Pairnal::Group.of(:alice)]
    )
    assert_empty session.pairs
  end

  def test_pairs_includes_all_combinations_from_a_mob
    session = Pairnal::Session.new(
      date: Date.new(2026, 1, 1),
      groups: [Pairnal::Group.of(:alice, :bob, :carol)]
    )
    assert_equal [[:alice, :bob], [:alice, :carol], [:bob, :carol]], session.pairs
  end
end
