module Pairnal
  module HistoryDsl
    class Session
      attr_reader :date, :groups

      def initialize(date, roster = nil)
        @date = date
        @roster = roster
        @groups = []
      end

      def solo(a)
        @groups << Group.of(resolve(a))
      end

      def pair(a, b)
        @groups << Group.of(resolve(a), resolve(b))
      end

      def mob(*people)
        raise ArgumentError, "a mob needs 3+ people, got #{people.size}" if people.size < 3

        @groups << Group.of(*people.map { |p| resolve(p) })
      end

      def to_session = Pairnal::Session.new(date:, groups:)

      private

      def resolve(person) = @roster ? @roster.resolve(person) : person
    end
  end
end
