# frozen_string_literal: true

require "test_helper"

class TestHistoryDslSession < Minitest::Test
  def test_pair_adds_a_two_person_group
    builder = Pairnal::HistoryDsl::Session.new(Date.new(2026, 1, 1))
    builder.pair(:alice, :bob)
    assert_equal 1, builder.groups.size
    assert_equal [:alice, :bob], builder.groups.first.members
  end

  def test_mob_adds_a_group_of_three_or_more
    builder = Pairnal::HistoryDsl::Session.new(Date.new(2026, 1, 1))
    builder.mob(:alice, :bob, :carol)
    assert_equal 1, builder.groups.size
    assert builder.groups.first.mob?
  end

  def test_mob_raises_for_fewer_than_three
    builder = Pairnal::HistoryDsl::Session.new(Date.new(2026, 1, 1))
    assert_raises(ArgumentError) { builder.mob(:alice, :bob) }
  end

  def test_to_session_returns_session_with_correct_date_and_groups
    date = Date.new(2026, 1, 1)
    builder = Pairnal::HistoryDsl::Session.new(date)
    builder.pair(:alice, :bob)
    session = builder.to_session
    assert_instance_of Pairnal::Session, session
    assert_equal date, session.date
    assert_equal 1, session.groups.size
  end
end

class TestHistoryDslHistory < Minitest::Test
  def test_roster_sets_people_on_built_history
    history = Pairnal::History.load { roster :alice, :bob, :carol }
    assert_equal [:alice, :bob, :carol], history.roster
  end

  def test_on_adds_a_dated_session
    history = Pairnal::History.load do
      roster :alice, :bob
      on("2026-01-01") { pair :alice, :bob }
    end
    assert_equal 1, history.sessions.size
    assert_equal Date.new(2026, 1, 1), history.sessions.first.date
  end

  def test_to_history_returns_history_instance
    history = Pairnal::History.load { roster :alice }
    assert_instance_of Pairnal::History, history
  end
end
