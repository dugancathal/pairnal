module Pairnal
  Session = Data.define(:date, :groups) do
    def pairs = groups.flat_map(&:pairs)
  end
end
