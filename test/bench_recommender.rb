# frozen_string_literal: true

require "test_helper"
require "minitest/benchmark"

# Recommender used to enumerate every possible pairing of members
# ((n-1)!! of them), so it got unusable fast as team size grew. It's now
# backed by Pairnal::Matching, a bitmask search that's exponential in the
# number of people instead. This checks the runtime actually tracks that
# exponential curve -- if a future change reintroduces factorial-style
# enumeration, the fit (or the wall-clock time) will give it away.
#
# Not part of `rake test` / `rake default`: run it explicitly with `rake
# bench` when touching the recommender's search.
class BenchRecommender < Minitest::Benchmark
  TODAY = Date.new(2026, 6, 5)

  def self.bench_range
    [8, 12, 16, 20]
  end

  def bench_recommend
    assert_performance_exponential 0.95 do |n|
      names = (1..n).map { |i| :"p#{i}" }
      history = Pairnal::History.load { roster(*names) }
      Pairnal::Recommender.new(history, today: TODAY).recommend(n: 3, members: names)
    end
  end
end
