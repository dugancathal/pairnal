module Pairnal
  module HistoryDsl
    class Session
      attr_reader :date, :groups

      def initialize(date)
        @date = date
        @groups = []
      end

      def pair(a, b)
        @groups << Group.of(a, b)
      end

      def mob(*people)
        raise ArgumentError, "a mob needs 3+ people, got #{people.size}" if people.size < 3

        @groups << Group.of(*people)
      end

      def to_session = Pairnal::Session.new(date:, groups:)
    end
  end
end
