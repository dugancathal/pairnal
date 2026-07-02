# frozen_string_literal: true

require "test_helper"
require "stringio"

class TestCommandsRecommend < Minitest::Test
  TODAY = Date.new(2026, 6, 5)

  def test_prints_three_options_by_default
    history = Pairnal::History.load { roster :alice, :bob, :carol, :dan }
    output = capture { |io| Pairnal::Cli::Commands::Recommend.new(history, today: TODAY).call(output: io) }
    assert_includes output, "Option 1"
    assert_includes output, "Option 2"
    assert_includes output, "Option 3"
    refute_includes output, "Option 4"
  end

  def test_header_includes_option_number_and_score
    history = Pairnal::History.load { roster :alice, :bob }
    output = capture { |io| Pairnal::Cli::Commands::Recommend.new(history, today: TODAY).call(output: io) }
    assert_match(/=== Option 1.*total staleness.*===/, output)
  end

  def test_lists_group_members_under_each_option
    history = Pairnal::History.load { roster :alice, :bob }
    output = capture { |io| Pairnal::Cli::Commands::Recommend.new(history, today: TODAY).call(output: io) }
    assert_includes output, "alice + bob"
  end

  def test_prints_a_section_per_declared_stream
    history = Pairnal::History.load do
      roster :alice, :bob, :carol, :dan
      stream :frontend, :alice, :bob
      stream :backend, :carol, :dan
    end
    output = capture { |io| Pairnal::Cli::Commands::Recommend.new(history, today: TODAY).call(output: io) }
    assert_includes output, "-- frontend --"
    assert_includes output, "-- backend --"
  end

  def test_prints_unassigned_section_for_leftover_members
    history = Pairnal::History.load do
      roster :alice, :bob, :carol
      stream :frontend, :alice, :bob
    end
    output = capture { |io| Pairnal::Cli::Commands::Recommend.new(history, today: TODAY).call(output: io) }
    assert_includes output, "-- frontend --"
    assert_includes output, "-- unassigned --"
  end

  def test_fixed_group_appears_in_every_option
    history = Pairnal::History.load { roster :alice, :bob, :carol, :dan, :eli, :frank }
    command = Pairnal::Cli::Commands::Recommend.new(history, today: TODAY)
    output = capture { |io| command.call(["alice+bob"], output: io) }
    assert_equal 3, output.scan("alice + bob").size
  end

  def test_anchor_pairs_person_with_someone
    history = Pairnal::History.load { roster :alice, :bob, :carol, :dan }
    command = Pairnal::Cli::Commands::Recommend.new(history, today: TODAY)
    output = capture { |io| command.call(["alice+"], output: io) }
    assert_match(/alice \+ \w+/, output)
  end

  def test_bare_name_is_a_fixed_solo
    history = Pairnal::History.load { roster :alice, :bob, :carol, :dan }
    command = Pairnal::Cli::Commands::Recommend.new(history, today: TODAY)
    output = capture { |io| command.call(["alice"], output: io) }
    assert_includes output, "alice  -- solo"
  end

  def test_unknown_member_raises
    history = Pairnal::History.load { roster :alice, :bob }
    command = Pairnal::Cli::Commands::Recommend.new(history, today: TODAY)
    assert_raises(ArgumentError) { command.call(["zeke+"], output: StringIO.new) }
  end

  def test_duplicate_member_raises
    history = Pairnal::History.load { roster :alice, :bob, :carol }
    command = Pairnal::Cli::Commands::Recommend.new(history, today: TODAY)
    assert_raises(ArgumentError) { command.call(["alice+", "alice+bob"], output: StringIO.new) }
  end

  def test_declaration_spanning_multiple_streams_raises
    history = Pairnal::History.load do
      roster :alice, :bob, :carol, :dan
      stream :frontend, :alice, :bob
      stream :backend, :carol, :dan
    end
    command = Pairnal::Cli::Commands::Recommend.new(history, today: TODAY)
    assert_raises(ArgumentError) { command.call(["alice+carol"], output: StringIO.new) }
  end

  private

  def capture
    io = StringIO.new
    yield io
    io.string
  end
end
