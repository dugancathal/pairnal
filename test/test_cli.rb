# frozen_string_literal: true

require "test_helper"
require "tempfile"
require "stringio"

class TestCli < Minitest::Test
  HISTORY_DSL = <<~DSL
    roster :alice, :bob, :carol, :dan
    on("2026-01-01") do
      pair :alice, :bob
      pair :carol, :dan
    end
  DSL

  def test_run_prints_three_options
    with_history_file do |path|
      output = capture_stdout { Pairnal::Cli.run(["--history", path]) }
      assert_includes output, "=== Option 1"
      assert_includes output, "=== Option 2"
      assert_includes output, "=== Option 3"
    end
  end

  def test_run_prints_score_for_each_option
    with_history_file do |path|
      output = capture_stdout { Pairnal::Cli.run(["--history", path]) }
      assert_match(/total staleness: \d+/, output)
    end
  end

  def test_run_prints_group_descriptions
    with_history_file do |path|
      output = capture_stdout { Pairnal::Cli.run(["--history", path]) }
      assert_match(/alice|bob|carol|dan/, output)
    end
  end

  private

  def with_history_file
    file = Tempfile.new(["history", ".rb"])
    file.write(HISTORY_DSL)
    file.close
    yield file.path
  ensure
    file&.unlink
  end

  def capture_stdout
    original = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original
  end
end
