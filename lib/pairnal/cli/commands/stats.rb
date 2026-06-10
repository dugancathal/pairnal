module Pairnal
  class Cli
    module Commands
      class Stats
        def initialize(history, since: nil)
          @history = history
          @since = since
        end

        def call(output: $stdout)
          counts = Pairnal::Stats.new(@history, since: @since).pair_counts
          header = @since ? "=== Pairing Leaderboard (since #{@since}) ===" : "=== Pairing Leaderboard ==="

          output.puts header
          counts.sort_by { |_, count| -count }.each do |group, count|
            output.puts "  #{group}: #{count} #{(count == 1) ? "time" : "times"}"
          end
        end
      end
    end
  end
end
