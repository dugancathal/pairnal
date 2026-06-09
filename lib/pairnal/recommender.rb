module Pairnal
  class Recommender
    NEVER_PAIRED_STALENESS = 365

    def initialize(history, today: Date.today, never_paired: NEVER_PAIRED_STALENESS)
      @history = history
      @today = today
      @never_paired = never_paired
      @last_paired = history.last_paired
    end

    def recommend(n: 3)
      allocations(@history.roster)
        .map { |alloc| Recommendation.new(allocation: alloc, score: score(alloc)) }
        .sort_by { |rec| -rec.score }
        .first(n)
    end

    def staleness(a, b)
      date = @last_paired[[a, b].sort]
      date ? (@today - date).to_i : @never_paired
    end

    def describe(group)
      return "#{group}  -- sits out" if group.solo?

      a, b = group.members
      if @last_paired[[a, b].sort]
        "#{group}  (#{staleness(a, b)}d since last worked together)"
      else
        "#{group}  (never paired)"
      end
    end

    private

    def score(alloc)
      alloc.groups.sum { |group| group.pairs.sum { |a, b| staleness(a, b) } }
    end

    def allocations(roster, &blk)
      return enum_for(:allocations, roster) unless blk

      members = roster.to_a
      if members.size.even?
        matchings(members) { |groups| yield Allocation.new(groups:) }
      else
        members.each_with_index do |out, i|
          rest = members[0...i] + members[(i + 1)..]
          matchings(rest) { |groups| yield Allocation.new(groups: groups + [Group.of(out)]) }
        end
      end
    end

    def matchings(people, &blk)
      return enum_for(:matchings, people) unless blk

      if people.empty?
        yield []
        return
      end

      first, *rest = people
      rest.each_with_index do |partner, i|
        remaining = rest[0...i] + rest[(i + 1)..]
        matchings(remaining) { |sub| yield([Group.of(first, partner)] + sub) }
      end
    end
  end
end
