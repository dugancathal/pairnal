# frozen_string_literal: true

require "test_helper"

class TestGroup < Minitest::Test
  def test_of_sorts_members
    assert_equal [:alice, :bob], Pairnal::Group.of(:bob, :alice).members
  end

  def test_solo_true_for_one_member
    assert Pairnal::Group.of(:alice).solo?
  end

  def test_solo_false_for_two_members
    refute Pairnal::Group.of(:alice, :bob).solo?
  end

  def test_pair_true_for_two_members
    assert Pairnal::Group.of(:alice, :bob).pair?
  end

  def test_pair_false_for_one_member
    refute Pairnal::Group.of(:alice).pair?
  end

  def test_pair_false_for_three_members
    refute Pairnal::Group.of(:alice, :bob, :carol).pair?
  end

  def test_mob_true_for_three_or_more_members
    assert Pairnal::Group.of(:alice, :bob, :carol).mob?
    assert Pairnal::Group.of(:alice, :bob, :carol, :dan).mob?
  end

  def test_mob_false_for_two_members
    refute Pairnal::Group.of(:alice, :bob).mob?
  end

  def test_pairs_returns_sorted_two_combinations
    group = Pairnal::Group.of(:alice, :bob, :carol)
    assert_equal [[:alice, :bob], [:alice, :carol], [:bob, :carol]], group.pairs
  end

  def test_pairs_sorts_each_pair
    group = Pairnal::Group.of(:bob, :alice)
    assert_equal [[:alice, :bob]], group.pairs
  end

  def test_pairs_empty_for_solo
    assert_empty Pairnal::Group.of(:alice).pairs
  end

  def test_to_s_joins_members_with_plus
    assert_equal "alice + bob", Pairnal::Group.of(:alice, :bob).to_s
  end

  def test_to_s_single_member
    assert_equal "alice", Pairnal::Group.of(:alice).to_s
  end
end
