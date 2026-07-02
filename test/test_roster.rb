# frozen_string_literal: true

require "test_helper"

class TestRoster < Minitest::Test
  def test_validate_members_bang_passes_for_known_members
    roster = Pairnal::Roster.new(alice: nil, bob: nil)
    roster.validate_members!([:alice, :bob])
  end

  def test_validate_members_bang_raises_for_unknown_member
    roster = Pairnal::Roster.new(alice: nil)
    assert_raises(ArgumentError) { roster.validate_members!([:alice, :nobody]) }
  end

  def test_validate_members_bang_raises_for_nil_member
    roster = Pairnal::Roster.new(alice: nil)
    assert_raises(ArgumentError) { roster.validate_members!([:alice, nil]) }
  end
end
