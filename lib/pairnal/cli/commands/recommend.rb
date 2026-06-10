module Pairnal
  class Cli
    module Commands
      class Recommend
        def initialize(history)
          @history = history
        end

        def call(output: $stdout)
          recommender = Recommender.new(@history)
          recommender.recommend(n: 3).each_with_index do |rec, i|
            output.puts "=== Option #{i + 1}  (total staleness: #{rec.score}) ==="
            rec.allocation.groups.each { |group| output.puts "  #{recommender.describe(group)}" }
            output.puts
          end
        end
      end
    end
  end
end
