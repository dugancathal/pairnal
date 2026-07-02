module Pairnal
  class Matching
    FORBIDDEN = -Float::INFINITY

    Result = Data.define(:weight, :pairs, :leftover)

    Pairing = Data.define(:i, :j) do
      def key = [i, j].sort
      def mask_bits = (1 << i) | (1 << j)
      def weight(weight_fn) = weight_fn.call(i, j)
    end

    Sitout = Data.define(:i) do
      def key = i
      def mask_bits = 1 << i
      def weight(_weight_fn) = 0
    end

    NO_CONSTRAINTS = {forced: [], forbidden: []}.freeze

    def initialize(n, weight:, leftover_eligible: ->(_i) { true })
      @n = n
      @weight = weight
      @leftover_eligible = leftover_eligible
      @full_mask = (1 << n) - 1
    end

    def top(k)
      return [] if k <= 0

      root = solve(**NO_CONSTRAINTS)
      return [] unless root

      results = []
      pending = [[root, NO_CONSTRAINTS]]
      until results.size == k || pending.empty?
        idx = pending.each_index.max_by { |i| pending[i][0].weight }
        result, constraints = pending.delete_at(idx)
        results << result
        pending.concat(branch(result, constraints))
      end
      results
    end

    private

    def solve(forced:, forbidden:)
      mask = @full_mask
      offset = 0
      forced.each do |decision|
        offset += decision.weight(@weight)
        mask &= ~decision.mask_bits
      end

      sitout_used = forced.any? { |d| d.is_a?(Sitout) }
      budget = sitout_used ? 0 : (bit_count(mask).odd? ? 1 : 0)

      forbidden_pairs = forbidden.grep(Pairing).to_h { |d| [d.key, true] }
      forbidden_sitouts = forbidden.grep(Sitout).to_h { |d| [d.key, true] }

      found = search(mask, budget, forbidden_pairs, forbidden_sitouts, {})
      return nil unless found

      forced_pairs = forced.grep(Pairing).map { |d| [d.i, d.j] }
      forced_sitout = forced.grep(Sitout).first&.i

      Result.new(weight: offset + found.weight, pairs: forced_pairs + found.pairs,
        leftover: forced_sitout || found.leftover)
    end

    def search(mask, budget, forbidden_pairs, forbidden_sitouts, memo)
      key = (mask << 1) | budget
      return memo[key] if memo.key?(key)

      if mask.zero?
        return memo[key] = Result.new(weight: 0, pairs: [], leftover: nil)
      end

      i = lowest_bit(mask)
      best = nil

      if budget.positive? && @leftover_eligible.call(i) && !forbidden_sitouts[i]
        sub = search(mask & ~(1 << i), budget - 1, forbidden_pairs, forbidden_sitouts, memo)
        best = better(best, Result.new(weight: sub.weight, pairs: sub.pairs, leftover: i)) if sub
      end

      partners = mask & ~(1 << i)
      while partners.nonzero?
        j = lowest_bit(partners)
        partners &= ~(1 << j)
        next if forbidden_pairs[[i, j].sort]

        w = @weight.call(i, j)
        next if w == FORBIDDEN

        sub = search(mask & ~(1 << i) & ~(1 << j), budget, forbidden_pairs, forbidden_sitouts, memo)
        next unless sub

        best = better(best, Result.new(weight: w + sub.weight, pairs: [[i, j]] + sub.pairs, leftover: sub.leftover))
      end

      memo[key] = best
    end

    def better(a, b) = (a && a.weight >= b.weight) ? a : b

    def lowest_bit(mask) = (mask & -mask).bit_length - 1

    def bit_count(mask) = mask.digits(2).count(1)

    def branch(result, constraints)
      pairs_already_forced = constraints[:forced].count { |d| d.is_a?(Pairing) }
      sitout_already_forced = constraints[:forced].any? { |d| d.is_a?(Sitout) }

      free_decisions = result.pairs.drop(pairs_already_forced).map { |i, j| Pairing.new(i:, j:) }
      free_decisions += [Sitout.new(i: result.leftover)] if result.leftover && !sitout_already_forced

      free_decisions.each_index.filter_map do |idx|
        new_constraints = {
          forced: constraints[:forced] + free_decisions[0...idx],
          forbidden: constraints[:forbidden] + [free_decisions[idx]]
        }

        candidate = solve(**new_constraints)
        [candidate, new_constraints] if candidate
      end
    end
  end
end
