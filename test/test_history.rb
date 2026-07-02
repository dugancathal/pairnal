# frozen_string_literal: true

require "test_helper"
require "tempfile"

class TestHistory < Minitest::Test
  def test_load_parses_dsl_block_into_history
    history = Pairnal::History.load do
      roster :alice, :bob
      on("2026-01-01") { pair :alice, :bob }
    end
    assert_equal [:alice, :bob], history.roster.members
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
    assert_equal [:alice, :bob], history.roster.members
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

  def test_stream_partitions_returns_single_unnamed_stream_when_none_declared
    history = Pairnal::History.load { roster :alice, :bob, :carol }
    partitions = history.stream_partitions
    assert_equal 1, partitions.size
    assert partitions.first.unnamed?
    assert_equal [:alice, :bob, :carol], partitions.first.members
  end

  def test_stream_partitions_returns_declared_streams_when_no_leftover
    history = Pairnal::History.load do
      roster :alice, :bob, :carol, :dan
      stream :frontend, :alice, :bob
      stream :backend, :carol, :dan
    end
    partitions = history.stream_partitions
    assert_equal %w[frontend backend], partitions.map(&:name)
  end

  def test_stream_partitions_appends_unassigned_for_leftover_members
    history = Pairnal::History.load do
      roster :alice, :bob, :carol
      stream :frontend, :alice, :bob
    end
    partitions = history.stream_partitions
    assert_equal ["frontend", "unassigned"], partitions.map(&:name)
    assert_equal [:carol], partitions.last.members
  end

  def test_stream_partitions_does_not_duplicate_multi_stream_members_into_unassigned
    history = Pairnal::History.load do
      roster :alice, :bob, :carol
      stream :frontend, :alice, :bob
      stream :backend, :alice, :carol
    end
    partitions = history.stream_partitions
    refute_includes partitions.map(&:name), "unassigned"
  end

  def test_stream_partitions_returns_a_fresh_array_when_fully_partitioned
    history = Pairnal::History.load do
      roster :alice, :bob
      stream :frontend, :alice, :bob
    end
    partitions = history.stream_partitions
    partitions << "mutated!"
    assert_equal 1, history.stream_partitions.size
  end
end
