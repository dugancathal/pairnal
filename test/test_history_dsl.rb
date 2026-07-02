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
    assert_instance_of Pairnal::Roster, history.roster
    assert_equal [:alice, :bob, :carol], history.roster.members
  end

  def test_roster_accepts_alias_name_pairs
    history = Pairnal::History.load { roster alice: "Alice Smith", bob: "Bob Jones" }
    assert_equal [:alice, :bob], history.roster.members
    assert_equal "Alice Smith", history.roster.display_name(:alice)
    assert_equal "Bob Jones", history.roster.display_name(:bob)
  end

  def test_on_adds_a_dated_session
    history = Pairnal::History.load do
      roster :alice, :bob
      on("2026-01-01") { pair :alice, :bob }
    end
    assert_equal 1, history.sessions.size
    assert_equal Date.new(2026, 1, 1), history.sessions.first.date
  end

  def test_pair_resolves_full_name_to_alias
    history = Pairnal::History.load do
      roster alice: "Alice Smith", bob: "Bob Jones"
      on("2026-01-01") { pair "Alice Smith", "Bob Jones" }
    end
    assert_equal [:alice, :bob], history.sessions.first.groups.first.members
  end

  def test_mob_resolves_full_names_to_aliases
    history = Pairnal::History.load do
      roster alice: "Alice Smith", bob: "Bob Jones", carol: "Carol White"
      on("2026-01-01") { mob "Alice Smith", "Bob Jones", "Carol White" }
    end
    assert_equal [:alice, :bob, :carol], history.sessions.first.groups.first.members
  end

  def test_to_history_returns_history_instance
    history = Pairnal::History.load { roster :alice }
    assert_instance_of Pairnal::History, history
  end

  def test_stream_adds_a_named_stream
    history = Pairnal::History.load do
      roster :alice, :bob, :carol
      stream :frontend, :alice, :bob
    end
    assert_equal 1, history.streams.size
    assert_equal "frontend", history.streams.first.name
    assert_equal [:alice, :bob], history.streams.first.members
  end

  def test_stream_resolves_full_names_to_aliases
    history = Pairnal::History.load do
      roster alice: "Alice Smith", bob: "Bob Jones"
      stream :frontend, "Alice Smith", "Bob Jones"
    end
    assert_equal [:alice, :bob], history.streams.first.members
  end

  def test_stream_raises_for_unknown_symbol_member
    assert_raises(ArgumentError) do
      Pairnal::History.load do
        roster :alice, :bob
        stream :frontend, :alice, :nobody
      end
    end
  end

  def test_stream_raises_argument_error_for_unknown_string_member
    assert_raises(ArgumentError) do
      Pairnal::History.load do
        roster :alice, :bob
        stream :frontend, "Not A Real Person"
      end
    end
  end

  def test_stream_raises_for_unsupported_member_type
    assert_raises(ArgumentError) do
      Pairnal::History.load do
        roster :alice, :bob
        stream :frontend, 42
      end
    end
  end

  def test_stream_raises_for_zero_members
    assert_raises(ArgumentError) do
      Pairnal::History.load do
        roster :alice, :bob
        stream :frontend
      end
    end
  end

  def test_stream_raises_for_reserved_unassigned_name
    assert_raises(ArgumentError) do
      Pairnal::History.load do
        roster :alice, :bob
        stream :unassigned, :alice, :bob
      end
    end
  end

  def test_stream_deduplicates_repeated_members
    history = Pairnal::History.load do
      roster :alice, :bob
      stream :frontend, :alice, :alice, :bob
    end
    assert_equal [:alice, :bob], history.streams.first.members
  end

  def test_stream_allows_a_person_in_multiple_streams
    history = Pairnal::History.load do
      roster :alice, :bob, :carol
      stream :frontend, :alice, :bob
      stream :backend, :alice, :carol
    end
    assert_equal 2, history.streams.size
    assert_equal [:alice, :bob], history.streams[0].members
    assert_equal [:alice, :carol], history.streams[1].members
  end
end
