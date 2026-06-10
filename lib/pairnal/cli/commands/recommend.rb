module Pairnal
  class Cli
    module Commands
      class Recommend
        def initialize(history, today: Date.today)
          @history = history
          @today = today
        end

        def call(output: $stdout)
          recommender = Recommender.new(@history, today: @today)
          recommender.recommend(n: 3).each_with_index do |rec, i|
            output.puts "=== Option #{i + 1}  (total staleness: #{rec.score}) ==="
            rec.allocation.groups.each { |group| output.puts "  #{describe_group(group, recommender)}" }
            output.puts
          end
        end

        private

        def describe_group(group, recommender)
          return "#{group}  -- solo" if group.solo?

          a, b = group.members
          if recommender.ever_paired?(a, b)
            "#{group}  (#{recommender.staleness(a, b)}d since last worked together)"
          else
            "#{group}  (never paired)"
          end
        end
      end
    end
  end
end
