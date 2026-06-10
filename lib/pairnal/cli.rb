require "optparse"

module Pairnal
  class Cli
    def self.run(args)
      options = {history: File.expand_path(".pair-history", Dir.pwd)}
      OptionParser.new do |opts|
        opts.on("--history PATH") { |p| options[:history] = p }
      end.parse!(args)

      command = args.shift || "recommend"
      history = History.load_path(options[:history])

      case command
      when "recommend" then Commands::Recommend.new(history).call
      when "stats"     then Commands::Stats.new(history).call
      end
    end
  end
end
