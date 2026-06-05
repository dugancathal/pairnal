# frozen_string_literal: true

require_relative "pairnal/version"
require "zeitwerk"
require "date"

loader = Zeitwerk::Loader.for_gem
loader.setup

module Pairnal
  class Error < StandardError; end
  # Your code goes here...
end
