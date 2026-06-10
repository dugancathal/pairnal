# frozen_string_literal: true

module Pairnal
  class Cli
    class GroupFormatter
      def initialize(recommender)
        @recommender = recommender
      end

      def call(group)
        return "#{group}  -- solo" if group.solo?
        return "#{group}  -- mob" if group.mob?

        a, b = group.members
        if @recommender.ever_paired?(a, b)
          "#{group}  (#{@recommender.staleness(a, b)}d since last worked together)"
        else
          "#{group}  (never paired)"
        end
      end
    end
  end
end
