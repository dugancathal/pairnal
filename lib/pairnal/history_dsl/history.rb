module Pairnal
  module HistoryDsl
    class History
      def initialize
        @roster = Roster.new({})
        @sessions = []
      end

      def roster(*people, **names)
        @roster = if names.any?
          Roster.new(names)
        else
          Roster.new(people.to_h { |p| [p, nil] })
        end
      end

      def on(date_str, &block)
        builder = Session.new(Date.iso8601(date_str), @roster)
        builder.instance_eval(&block)
        @sessions << builder.to_session
      end

      def to_history = Pairnal::History.new(roster: @roster, sessions: @sessions)
    end
  end
end
