module Pairnal
  module HistoryDsl
    class History
      def initialize
        @roster = Roster.new({})
        @sessions = []
        @streams = []
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

      def stream(name, *members)
        raise ArgumentError, "stream needs at least 1 member, got 0" if members.empty?
        raise ArgumentError, "stream name \"unassigned\" is reserved" if name.to_s == "unassigned"

        resolved = members.map { |m| resolve_stream_member(m) }.uniq
        @roster.validate_members!(resolved)

        @streams << Pairnal::Stream.new(name: name.to_s, members: resolved)
      end

      def to_history = Pairnal::History.new(roster: @roster, sessions: @sessions, streams: @streams)

      private

      def resolve_stream_member(identifier)
        case identifier
        when Symbol, String then @roster.resolve(identifier)
        else identifier
        end
      rescue KeyError
        identifier
      end
    end
  end
end
