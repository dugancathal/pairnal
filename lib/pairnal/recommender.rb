module Pairnal
  class Recommender
    NEVER_PAIRED_STALENESS = 365

    def initialize(history, today: Date.today, never_paired: NEVER_PAIRED_STALENESS)
      @history = history
      @today = today
      @never_paired = never_paired
      @last_paired = history.last_paired
      @sessions_by_date = history.sessions.sort_by(&:date)
    end

    def recommend(n: 3, members: @history.roster.members, fixed: [], anchors: [])
      committed = fixed.flat_map(&:members) + anchors.flatten
      free = members.to_a - committed
      units = anchors.map(&:dup) + free.map { |m| [m] }
      free_start = anchors.size

      base_score = fixed.sum { |group| internal_staleness(group.members) } +
        units.sum { |unit| internal_staleness(unit) }

      matcher = Matching.new(units.size,
        weight: ->(i, j) { (i < free_start && j < free_start) ? Matching::FORBIDDEN : cross_staleness(units[i], units[j]) },
        leftover_eligible: ->(i) { i >= free_start })

      matcher.top(n).map do |result|
        groups = fixed + result.pairs.map { |i, j| Group.of(*units[i], *units[j]) }
        groups += [Group.of(*units[result.leftover])] if result.leftover
        Recommendation.new(allocation: Allocation.new(groups:), score: base_score + result.weight)
      end
    end

    def staleness(a, b)
      date = @last_paired[[a, b].sort]
      date ? (@today - date).to_i : @never_paired
    end

    def ever_paired?(a, b) = @last_paired[[a, b].sort]

    def over_paired?(a, b, streak: 2)
      recent = @sessions_by_date.last(streak)
      recent.size == streak && recent.all? { |s| s.pairs.include?([a, b].sort) }
    end

    private

    def internal_staleness(members) = members.combination(2).sum { |a, b| staleness(a, b) }

    def cross_staleness(unit_a, unit_b)
      unit_a.sum { |a| unit_b.sum { |b| staleness(a, b) } }
    end
  end
end
