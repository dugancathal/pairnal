module Pairnal
  class Cli
    module Commands
      class Record
        def initialize(roster, history_path)
          @roster = roster
          @history_path = history_path
        end

        def call(args, date: Date.today, output: $stdout)
          groups = parse_groups(args)
          validate!(groups)
          append_session(date, groups)
          output.puts "Recorded #{groups.size} group(s) for #{date}"
        end

        private

        def parse_groups(args)
          args.map { |arg| arg.split("+").map(&:to_sym) }
        end

        def validate!(groups)
          unknown = groups.flatten.reject { |a| @roster.include?(a) }
          raise ArgumentError, "unknown roster members: #{unknown.join(", ")}" if unknown.any?
        end

        def append_session(date, groups)
          File.open(@history_path, "a") do |f|
            f.puts
            f.puts "on #{date.iso8601.inspect} do"
            groups.each do |members|
              f.puts "  #{dsl_method(members)} #{members.map(&:inspect).join(", ")}"
            end
            f.puts "end"
          end
        end

        def dsl_method(members)
          case members.size
          when 1 then "solo"
          when 2 then "pair"
          else "mob"
          end
        end
      end
    end
  end
end
