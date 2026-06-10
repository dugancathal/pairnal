# frozen_string_literal: true

require "test_helper"
require "tempfile"
require "stringio"

class TestCommandsRecord < Minitest::Test
  TODAY = Date.new(2026, 6, 9)

  def test_appends_on_block_with_correct_date
    with_history_file do |roster, path|
      call(roster, path, ["alice+bob"], date: TODAY)
      assert_includes File.read(path), 'on "2026-06-09" do'
    end
  end

  def test_writes_pair_for_two_members
    with_history_file do |roster, path|
      call(roster, path, ["alice+bob"], date: TODAY)
      assert_includes File.read(path), "  pair :alice, :bob"
    end
  end

  def test_writes_mob_for_three_or_more_members
    with_history_file do |roster, path|
      call(roster, path, ["alice+bob+carol"], date: TODAY)
      assert_includes File.read(path), "  mob :alice, :bob, :carol"
    end
  end

  def test_writes_solo_for_one_member
    with_history_file do |roster, path|
      call(roster, path, ["dan"], date: TODAY)
      assert_includes File.read(path), "  solo :dan"
    end
  end

  def test_writes_multiple_groups
    with_history_file do |roster, path|
      call(roster, path, ["alice+bob", "carol+dan"], date: TODAY)
      content = File.read(path)
      assert_includes content, "  pair :alice, :bob"
      assert_includes content, "  pair :carol, :dan"
    end
  end

  def test_raises_for_unknown_alias
    with_history_file do |roster, path|
      assert_raises(ArgumentError) { call(roster, path, ["alice+zork"], date: TODAY) }
    end
  end

  def test_error_message_names_unknown_members
    with_history_file do |roster, path|
      error = assert_raises(ArgumentError) { call(roster, path, ["alice+zork"], date: TODAY) }
      assert_includes error.message, "zork"
    end
  end

  def test_prints_confirmation
    with_history_file do |roster, path|
      io = StringIO.new
      Pairnal::Cli::Commands::Record.new(roster, path).call(["alice+bob", "carol+dan"], date: TODAY, output: io)
      assert_includes io.string, "2 group(s)"
      assert_includes io.string, "2026-06-09"
    end
  end

  private

  def call(roster, path, args, date:)
    Pairnal::Cli::Commands::Record.new(roster, path).call(args, date:, output: StringIO.new)
  end

  def with_history_file
    file = Tempfile.new(["history", ".rb"])
    file.write("roster :alice, :bob, :carol, :dan\n")
    file.close
    history = Pairnal::History.load_path(file.path)
    yield history.roster, file.path
  ensure
    file&.unlink
  end
end
