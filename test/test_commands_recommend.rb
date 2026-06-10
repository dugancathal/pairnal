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


  private

  def capture
    io = StringIO.new
    yield io
    io.string
  end
end
