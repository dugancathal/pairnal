# frozen_string_literal: true

module Pairnal
  class Cli
    module Commands
      class Show
        def initialize(history)
          @history = history
        end

        def call(args, output: $stdout)
          name = args.first or raise ArgumentError, "usage: pairnal show <person>"
          person = @history.roster.resolve(name.to_sym)
          raise ArgumentError, "unknown roster member: #{name}" unless @history.roster.include?(person)

          counts = Pairnal::Stats.new(@history).pair_counts
          others = @history.roster.to_a - [person]

          paired, never = others.partition { |other| counts[Group.of(person, other)]&.positive? }
          paired.sort_by! { |other| -counts[Group.of(person, other)] }

          output.puts "=== #{person} ==="
          paired.each do |other|
            count = counts[Group.of(person, other)]
            output.puts "  #{other}: #{count} #{count == 1 ? "time" : "times"}"
          end
          output.puts "  (never paired with: #{never.join(", ")})" if never.any?
        end
      end
    end
  end
end
