module Pairnal
  class Stats
    def initialize(history, since: nil)
      sessions = history.sessions
      sessions = sessions.select { |s| s.date >= since } if since
      @sessions = sessions
    end

    def pair_counts
      @sessions.each_with_object(Hash.new(0)) do |session, counts|
        session.pairs.each { |pair| counts[Group.of(*pair)] += 1 }
      end
    end
  end
end
