module Pairnal
  class Recommender
    NEVER_PAIRED_STALENESS = 365

    def initialize(history, today: Date.today, never_paired: NEVER_PAIRED_STALENESS)
      @history = history
      @today = today
      @never_paired = never_paired
      @last_paired = history.last_paired
    end

    def recommend(n: 3, members: @history.roster.members, fixed: [], anchors: [])
      allocations(members, fixed:, anchors:)
        .map { |alloc| Recommendation.new(allocation: alloc, score: score(alloc)) }
        .sort_by { |rec| -rec.score }
        .first(n)
    end

    def staleness(a, b)
      date = @last_paired[[a, b].sort]
      date ? (@today - date).to_i : @never_paired
    end

    def ever_paired?(a, b) = @last_paired[[a, b].sort]

    def over_paired?(a, b, streak: 2)
      recent = @history.sessions.sort_by(&:date).last(streak)
      recent.size == streak && recent.all? { |s| s.pairs.include?([a, b].sort) }
    end

    private

    def score(alloc)
      alloc.groups.sum { |group| group.pairs.sum { |a, b| staleness(a, b) } }
    end

    def allocations(members, fixed: [], anchors: [], &blk)
      return enum_for(:allocations, members, fixed:, anchors:) unless blk

      committed = fixed.flat_map(&:members) + anchors.flatten
      free = members.to_a - committed
      anchor_units = anchors.map(&:dup)
      free_units = free.zip
      units = anchor_units + free_units

      if units.size.even?
        matchings(units, anchor_units:) { |groups| yield Allocation.new(groups: fixed + groups) }
      else
        free_units.each_with_index do |out, i|
          rest = anchor_units + free_units[0...i] + free_units[(i + 1)..]
          matchings(rest, anchor_units:) { |groups| yield Allocation.new(groups: fixed + groups + [Group.of(*out)]) }
        end
      end
    end

    def matchings(units, anchor_units: [], &blk)
      return enum_for(:matchings, units, anchor_units:) unless blk

      if units.empty?
        yield []
        return
      end

      first, *rest = units
      first_anchored = anchor_units.any? { |a| a.equal?(first) }
      rest.each_with_index do |partner, i|
        next if first_anchored && anchor_units.any? { |a| a.equal?(partner) }

        remaining = rest[0...i] + rest[(i + 1)..]
        matchings(remaining, anchor_units:) { |sub| yield([Group.of(*first, *partner)] + sub) }
      end
    end
  end
end
