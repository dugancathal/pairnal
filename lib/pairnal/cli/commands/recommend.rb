module Pairnal
  class Cli
    module Commands
      class Recommend
        LARGE_PARTITION_WARNING_SIZE = 14

        def initialize(history, today: Date.today, large_partition_warning_size: LARGE_PARTITION_WARNING_SIZE)
          @history = history
          @today = today
          @large_partition_warning_size = large_partition_warning_size
        end

        def call(output: $stdout)
          recommender = Recommender.new(@history, today: @today)
          formatter = GroupFormatter.new(recommender)
          @history.stream_partitions.each do |stream|
            output.puts "-- #{stream.name} --" unless stream.unnamed?
            if stream.members.size > @large_partition_warning_size
              output.puts "  (warning: #{stream.members.size} people in this group -- " \
                          "generating recommendations may be slow; consider splitting into streams)"
            end
            recommender.recommend(n: 3, members: stream.members).each_with_index do |rec, i|
              output.puts "=== Option #{i + 1}  (total staleness: #{rec.score}) ==="
              rec.allocation.groups.each { |group| output.puts "  #{formatter.call(group)}" }
              output.puts
            end
          end
        end
      end
    end
  end
end
