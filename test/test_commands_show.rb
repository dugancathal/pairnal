# frozen_string_literal: true

require "test_helper"
require "stringio"

class TestCommandsShow < Minitest::Test
  def setup
    @history = Pairnal::History.load do
      roster :alice, :bob, :carol, :dan
      on("2026-01-01") { pair :alice, :bob }
      on("2026-01-08") { pair :alice, :bob }
      on("2026-01-15") { pair :alice, :carol }
    end
  end

  def test_prints_header_with_person_name
    output = capture { |io| Pairnal::Cli::Commands::Show.new(@history).call(["alice"], output: io) }
    assert_includes output, "=== alice ==="
  end

  def test_lists_partners_with_counts
    output = capture { |io| Pairnal::Cli::Commands::Show.new(@history).call(["alice"], output: io) }
    assert_includes output, "bob: 2 times"
    assert_includes output, "carol: 1 time"
  end

  def test_lookup_is_reciprocal
    output_alice = capture { |io| Pairnal::Cli::Commands::Show.new(@history).call(["alice"], output: io) }
    output_bob = capture { |io| Pairnal::Cli::Commands::Show.new(@history).call(["bob"], output: io) }
    assert_includes output_alice, "bob: 2 times"
    assert_includes output_bob, "alice: 2 times"
  end

  def test_sorts_partners_by_count_descending
    output = capture { |io| Pairnal::Cli::Commands::Show.new(@history).call(["alice"], output: io) }
    bob_pos = output.index("bob")
    carol_pos = output.index("carol")
    assert bob_pos < carol_pos
  end

  def test_lists_never_paired_members
    output = capture { |io| Pairnal::Cli::Commands::Show.new(@history).call(["alice"], output: io) }
    assert_includes output, "never paired with: dan"
  end

  def test_omits_never_paired_line_when_all_paired
    history = Pairnal::History.load do
      roster :alice, :bob
      on("2026-01-01") { pair :alice, :bob }
    end
    output = capture { |io| Pairnal::Cli::Commands::Show.new(history).call(["alice"], output: io) }
    refute_includes output, "never paired"
  end

  def test_raises_on_unknown_person
    assert_raises(ArgumentError) do
      Pairnal::Cli::Commands::Show.new(@history).call(["zed"])
    end
  end

  def test_raises_when_no_args
    assert_raises(ArgumentError) do
      Pairnal::Cli::Commands::Show.new(@history).call([])
    end
  end

  private

  def capture
    io = StringIO.new
    yield io
    io.string
  end
end
