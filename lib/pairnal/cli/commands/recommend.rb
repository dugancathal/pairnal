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
          formatter = GroupFormatter.new(recommender)
          recommender.recommend(n: 3).each_with_index do |rec, i|
            output.puts "=== Option #{i + 1}  (total staleness: #{rec.score}) ==="
            rec.allocation.groups.each { |group| output.puts "  #{formatter.call(group)}" }
            output.puts
          end
        end
      end
    end
  end
end
