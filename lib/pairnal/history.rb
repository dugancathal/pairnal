module Pairnal
  History = Data.define(:roster, :sessions, :streams) do
    def initialize(roster:, sessions:, streams: [])
      super
    end

    def self.load_path(path)
      dsl = HistoryDsl::History.new
      dsl.instance_eval(File.read(path), path)
      dsl.to_history
    end

    def self.load(&block)
      dsl = HistoryDsl::History.new
      dsl.instance_eval(&block)
      dsl.to_history
    end

    def last_paired
      sessions.each_with_object({}) do |session, acc|
        session.pairs.each do |key|
          acc[key] = session.date if acc[key].nil? || acc[key] < session.date
        end
      end
    end

    def stream_partitions
      return [Stream.new(name: nil, members: roster.members)] if streams.empty?

      assigned = streams.flat_map(&:members).uniq
      leftover = roster.members - assigned
      leftover.empty? ? streams.dup : streams + [Stream.new(name: "unassigned", members: leftover)]
    end
  end
end
