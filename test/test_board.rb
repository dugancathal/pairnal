# frozen_string_literal: true

require "test_helper"
require "tempfile"
require "stringio"

class TestBoard < Minitest::Test
  TODAY = Date.new(2026, 6, 9)

  def test_state_lists_roster_members_and_display_names
    with_history_file(<<~HISTORY) do |path|
      roster alice: "Alice A", bob: "Bob B"
    HISTORY
      state = board(path).state
      assert_equal({"alice" => "Alice A", "bob" => "Bob B"}, state[:displayNames])
    end
  end

  def test_state_includes_stream_partitions_with_unassigned
    with_history_file(<<~HISTORY) do |path|
      roster :alice, :bob, :carol
      stream :frontend, :alice, :bob
    HISTORY
      state = board(path).state
      names = state[:streams].map { |s| s[:name] }
      assert_includes names, "frontend"
      assert_includes names, "unassigned"
      unassigned = state[:streams].find { |s| s[:name] == "unassigned" }
      assert_equal ["carol"], unassigned[:members]
    end
  end

  def test_state_preloads_groups_from_the_most_recent_session
    with_history_file(<<~HISTORY) do |path|
      roster :alice, :bob, :carol, :dan
      on "2026-06-01" do
        pair :alice, :bob
      end
      on "2026-06-08" do
        pair :alice, :carol
        pair :bob, :dan
      end
    HISTORY
      stream = board(path).state[:streams].find { |s| s[:name].nil? }
      assert_includes stream[:groups], %w[alice carol]
      assert_includes stream[:groups], %w[bob dan]
    end
  end

  def test_state_drops_previous_groupmates_no_longer_in_the_stream
    with_history_file(<<~HISTORY) do |path|
      roster :alice, :bob, :carol
      stream :frontend, :alice, :bob
      on "2026-06-08" do
        pair :alice, :carol
      end
    HISTORY
      frontend = board(path).state[:streams].find { |s| s[:name] == "frontend" }
      assert_equal [["alice"]], frontend[:groups]
    end
  end

  def test_state_has_no_preloaded_groups_without_history
    with_history_file(<<~HISTORY) do |path|
      roster :alice, :bob
    HISTORY
      stream = board(path).state[:streams].first
      assert_empty stream[:groups]
    end
  end

  def test_state_reports_staleness_between_every_pair
    with_history_file(<<~HISTORY) do |path|
      roster :alice, :bob
      on "2026-06-04" do
        pair :alice, :bob
      end
    HISTORY
      state = board(path).state
      info = state[:staleness]["alice|bob"]
      assert_equal 5, info[:days]
      assert info[:everPaired]
    end
  end

  def test_state_flags_never_paired
    with_history_file(<<~HISTORY) do |path|
      roster :alice, :bob
    HISTORY
      info = board(path).state[:staleness]["alice|bob"]
      refute info[:everPaired]
      assert_equal 365, info[:days]
    end
  end

  def test_state_flags_over_paired
    with_history_file(<<~HISTORY) do |path|
      roster :alice, :bob
      on "2026-06-03" do
        pair :alice, :bob
      end
      on "2026-06-04" do
        pair :alice, :bob
      end
    HISTORY
      info = board(path).state[:staleness]["alice|bob"]
      assert info[:overPaired]
    end
  end

  def test_suggest_treats_two_person_groups_on_the_board_as_fixed
    with_history_file(<<~HISTORY) do |path|
      roster :alice, :bob, :carol, :dan
      stream :everyone, :alice, :bob, :carol, :dan
    HISTORY
      result = board(path).suggest("stream" => "everyone", "groups" => [%w[alice bob]])
      result[:options].each do |option|
        assert_includes option[:groups], %w[alice bob]
      end
    end
  end

  def test_suggest_treats_one_person_groups_as_anchors
    with_history_file(<<~HISTORY) do |path|
      roster :alice, :bob, :carol, :dan
      stream :everyone, :alice, :bob, :carol, :dan
    HISTORY
      result = board(path).suggest("stream" => "everyone", "groups" => [["alice"]])
      result[:options].each do |option|
        group = option[:groups].find { |g| g.include?("alice") }
        assert_operator group.size, :>=, 2
      end
    end
  end

  def test_suggest_unknown_stream_returns_an_error
    with_history_file(<<~HISTORY) do |path|
      roster :alice, :bob
    HISTORY
      result = board(path).suggest("stream" => "nope", "groups" => [])
      assert result[:error]
    end
  end

  def test_save_appends_a_session_across_every_stream
    with_history_file(<<~HISTORY) do |path|
      roster :alice, :bob, :carol, :dan
    HISTORY
      result = board(path, today: TODAY).save("groups" => [%w[alice bob], %w[carol dan]])
      assert result[:ok]
      content = File.read(path)
      assert_includes content, 'on "2026-06-09" do'
      assert_includes content, "  pair :alice, :bob"
      assert_includes content, "  pair :carol, :dan"
    end
  end

  def test_save_with_no_groups_returns_an_error_and_does_not_touch_the_file
    with_history_file(<<~HISTORY) do |path|
      roster :alice, :bob
    HISTORY
      before = File.read(path)
      result = board(path, today: TODAY).save("groups" => [])
      assert result[:error]
      assert_equal before, File.read(path)
    end
  end

  def test_save_with_unknown_member_returns_an_error
    with_history_file(<<~HISTORY) do |path|
      roster :alice, :bob
    HISTORY
      result = board(path, today: TODAY).save("groups" => [%w[alice zork]])
      assert result[:error]
      assert_includes result[:error], "zork"
    end
  end

  private

  def board(path, today: TODAY) = Pairnal::Board.new(history_path: path, today:, output: StringIO.new)

  def with_history_file(content)
    file = Tempfile.new(["history", ".rb"])
    file.write(content)
    file.close
    yield file.path
  ensure
    file&.unlink
  end
end
