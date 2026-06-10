module Pairnal
  class Stats
    def initialize(history)
      @history = history
    end

    def pair_counts
      @history.sessions.each_with_object(Hash.new(0)) do |session, counts|
        session.pairs.each { |pair| counts[Group.of(*pair)] += 1 }
      end
    end
  end
end
