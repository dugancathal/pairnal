module Pairnal
  Stream = Data.define(:name, :members) do
    def unnamed? = name.nil?
  end
end
