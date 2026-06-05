module Pairnal
  module HistoryDsl
    class History
      def initialize
        @roster = []
        @sessions = []
      end

      def roster(*people)
        @roster = people
      end

      def on(date_str, &block)
        builder = Session.new(Date.iso8601(date_str))
        builder.instance_eval(&block)
        @sessions << builder.to_session
      end

      def to_history = Pairnal::History.new(roster: @roster, sessions: @sessions)
    end
  end
end
