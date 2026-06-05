require "optparse"

module Pairnal
  class Cli
    def self.run(args)
      options = {history: File.expand_path(".pair-history", Dir.pwd)}
      OptionParser.new do |opts|
        opts.on("--history PATH") { |p| options[:history] = p }
      end.parse!(args)

      history = History.load_path(options[:history])
      recommender = Recommender.new(history)
      recommender.recommend(n: 3).each_with_index do |rec, i|
        puts "=== Option #{i + 1}  (total staleness: #{rec.score}) ==="
        rec.allocation.groups.each { |group| puts "  #{recommender.describe(group)}" }
        puts
      end
    end
  end
end
