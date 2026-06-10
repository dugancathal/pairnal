module Pairnal
  class Cli
    module Commands
      class Stats
        def initialize(history)
          @history = history
        end

        def call(output: $stdout)
          counts = pair_counts

          output.puts "=== Pairing Leaderboard ==="
          counts.sort_by { |_, count| -count }.each do |(a, b), count|
            output.puts "  #{a} + #{b}: #{count} #{count == 1 ? "time" : "times"}"
          end
        end

        private

        def pair_counts
          @history.sessions.each_with_object(Hash.new(0)) do |session, counts|
            session.pairs.each { |pair| counts[pair] += 1 }
          end
        end
      end
    end
  end
end
