require "optparse"

module Pairnal
  class Cli
    def self.run(args)
      options = {history: File.expand_path(".pair-history", Dir.pwd), date: Date.today, since: nil}
      OptionParser.new do |opts|
        opts.on("--history PATH") { |p| options[:history] = p }
        opts.on("--date DATE") { |d| options[:date] = Date.iso8601(d) }
        opts.on("--since DATE") { |d| options[:since] = Date.iso8601(d) }
      end.parse!(args)

      command = args.shift || "recommend"
      history = History.load_path(options[:history])

      case command
      when "recommend" then Commands::Recommend.new(history).call
      when "stats" then Commands::Stats.new(history, since: options[:since]).call
      when "show" then Commands::Show.new(history).call(args)
      when "record" then Commands::Record.new(history.roster, options[:history]).call(args, date: options[:date])
      end
    end
  end
end
