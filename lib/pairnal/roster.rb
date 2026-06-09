module Pairnal
  class Roster
    include Enumerable

    attr_reader :members

    def initialize(members)
      @members = members.freeze
    end

    def each(&) = @members.each(&)
    def size = @members.size
    def empty? = @members.empty?
    def [](index) = @members[index]

    def ==(other)
      case other
      when Roster then @members == other.members
      end
    end
  end
end
