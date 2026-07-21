# frozen_string_literal: true

require_relative "lib/pairnal/version"

Gem::Specification.new do |spec|
  spec.name = "pairnal"
  spec.version = Pairnal::VERSION
  spec.authors = ["TJ Taylor"]
  spec.email = ["dugancathal@gmail.com"]

  spec.summary = "A library and small CLI for examining and recommending pair-programmer rotations"
  spec.homepage = "https://github.com/dugancathal/pairnal"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/dugancathal/pairnal"
  spec.metadata["changelog_uri"] = "https://github.com/dugancathal/pairnal/blob/main/CHANGELOG.md"

  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore test/ .standard.yml])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "puma", "~> 6.0"
  spec.add_dependency "sinatra", "~> 4.0"
  spec.add_dependency "zeitwerk", "~> 2.8"
end
