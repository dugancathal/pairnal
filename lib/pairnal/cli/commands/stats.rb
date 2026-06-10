module Pairnal
  class Cli
    module Commands
      class Stats
        def initialize(history)
          @history = history
        end

        def call(output: $stdout)
          counts = Pairnal::Stats.new(@history).pair_counts

          output.puts "=== Pairing Leaderboard ==="
          counts.sort_by { |_, count| -count }.each do |group, count|
            output.puts "  #{group}: #{count} #{(count == 1) ? "time" : "times"}"
          end
        end
      end
    end
  end
end
