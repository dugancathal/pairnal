module Pairnal
  class Cli
    module Commands
      class Recommend
        def initialize(history, today: Date.today)
          @history = history
          @today = today
        end

        def call(args = [], output: $stdout)
          declarations = parse_declarations(args)
          validate!(declarations)

          recommender = Recommender.new(@history, today: @today)
          formatter = GroupFormatter.new(recommender)
          @history.stream_partitions.each do |stream|
            fixed, anchors = declarations_for(declarations, stream)
            output.puts "-- #{stream.name} --" unless stream.unnamed?
            recs = recommender.recommend(n: 3, members: stream.members, fixed:, anchors:)
            if recs.empty? && (fixed.any? || anchors.any?)
              output.puts "  (no valid pairing satisfies the given constraints)"
            end
            recs.each_with_index do |rec, i|
              output.puts "=== Option #{i + 1}  (total staleness: #{rec.score}) ==="
              rec.allocation.groups.each { |group| output.puts "  #{formatter.call(group)}" }
              output.puts
            end
          end
        end

        private

        def parse_declarations(args)
          args.map do |arg|
            fill = arg.end_with?("+")
            names = arg.delete_suffix("+").split("+").map(&:to_sym)
            {members: names, fill: fill}
          end
        end

        def validate!(declarations)
          all_members = declarations.flat_map { |d| d[:members] }
          raise ArgumentError, "empty group in recommend arguments" if declarations.any? { |d| d[:members].empty? }

          @history.roster.validate_members!(all_members)

          dupes = all_members.tally.select { |_, count| count > 1 }.keys
          raise ArgumentError, "member(s) specified more than once: #{dupes.join(", ")}" if dupes.any?

          @history.stream_partitions.each do |stream|
            declarations.each do |d|
              next if (d[:members] & stream.members).empty?

              unless (d[:members] - stream.members).empty?
                raise ArgumentError, "#{d[:members].join("+")} spans multiple streams"
              end
            end
          end
        end

        def declarations_for(declarations, stream)
          relevant = declarations.select { |d| (d[:members] - stream.members).empty? }
          fixed = relevant.reject { |d| d[:fill] }.map { |d| Group.of(*d[:members]) }
          anchors = relevant.select { |d| d[:fill] }.map { |d| d[:members] }
          [fixed, anchors]
        end
      end
    end
  end
end
