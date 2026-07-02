# frozen_string_literal: true

require "test_helper"

class TestStream < Minitest::Test
  def test_exposes_name_and_members
    stream = Pairnal::Stream.new(name: "frontend", members: [:alice, :bob])
    assert_equal "frontend", stream.name
    assert_equal [:alice, :bob], stream.members
  end

  def test_unnamed_true_when_name_is_nil
    assert Pairnal::Stream.new(name: nil, members: [:alice]).unnamed?
  end

  def test_unnamed_false_when_name_is_present
    refute Pairnal::Stream.new(name: "frontend", members: [:alice]).unnamed?
  end
end
