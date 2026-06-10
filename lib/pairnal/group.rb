module Pairnal
  Group = Data.define(:members) do
    def self.of(*members) = new(members: members.sort)

    def solo? = members.size == 1
    def pair? = members.size == 2
    def mob? = members.size >= 3

    def pairs
      members.combination(2).to_a
    end

    def to_s = members.join(" + ")
  end
end
