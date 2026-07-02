# frozen_string_literal: true

require "bundler/gem_tasks"
require "minitest/test_task"

Minitest::TestTask.create

Minitest::TestTask.create :bench do |t|
  t.test_globs = ["test/bench_*.rb"]
end

require "standard/rake"

task default: %i[test standard]
