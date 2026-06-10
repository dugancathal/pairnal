module Pairnal
  class Roster
    include Enumerable

    def initialize(members)
      # members: { alias_sym => display_name_string_or_nil }
      @members = members.freeze
      @by_name = members.filter_map { |k, v| [v, k] if v }.to_h.freeze
    end

    def each(&) = @members.each_key(&)
    def size = @members.size
    def empty? = @members.empty?

    def members = @members.keys

    def display_name(id) = @members[id] || id.to_s

    def resolve(identifier)
      case identifier
      when Symbol then identifier
      when String then @by_name.fetch(identifier) { raise KeyError, "unknown roster member: #{identifier.inspect}" }
      end
    end

    def ==(other)
      case other
      when Roster then members == other.members
      end
    end
  end
end
