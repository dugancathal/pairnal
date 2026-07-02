require "optparse"

module Pairnal
  class Cli
    def self.subcommands = {
      recommend: "[default command] review history and provide a recommended pairing rotation for today",
      stats: "print a pairing leaderboard for the team",
      show: "provided a pair's name, shows their individual stats",
      record: "record pairs for today - e.g. me+you+them aSolo"
    }

    def self.run(args)
      options = {history: File.expand_path(".pair-history", Dir.pwd), date: Date.today, since: nil}
      OptionParser.new do |opts|
        opts.banner = "pairnal [global opts] command [command opts]"
        opts.separator ""
        opts.separator "Available commands:"
        subcommands.each { |name, desc| opts.separator "    #{name.to_s.ljust(12)}\t #{desc}" }
        opts.separator ""

        opts.separator "Global options:"
        opts.on("-p", "--history-path PATH") { |p| options[:history] = p }
        opts.on("-d", "--date DATE") { |d| options[:date] = Date.iso8601(d) }
        opts.on("-s", "--since DATE") { |d| options[:since] = Date.iso8601(d) }

        opts.on_tail("-h", "--help") do
          puts opts

          exit
        end
      end.order!(args)

      command = subcommands.key?(args.first&.to_sym) ? args.shift : "recommend"
      history = History.load_path(options[:history])

      case command
      when "recommend" then Commands::Recommend.new(history).call(args)
      when "stats" then Commands::Stats.new(history, since: options[:since]).call
      when "show" then Commands::Show.new(history).call(args)
      when "record" then Commands::Record.new(history.roster, options[:history]).call(args, date: options[:date])
      end
    end
  end
end
