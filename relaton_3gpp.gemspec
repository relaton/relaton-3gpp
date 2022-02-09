# frozen_string_literal: true

require_relative "lib/relaton_3gpp/version"

Gem::Specification.new do |spec|
  spec.name          = "relaton-3gpp"
  spec.version       = Relaton3gpp::VERSION
  spec.authors       = ["Ribose Inc."]
  spec.email         = ["open.source@ribose.com"]

  spec.summary       = "RelatonIana: Ruby XMLDOC impementation."
  spec.description   = "RelatonIana: Ruby XMLDOC impementation."
  spec.homepage      = "https://github.com/relaton/relaton-iana"
  spec.license       = "BSD-2-Clause"
  spec.required_ruby_version = ">= 2.5.0"

  # spec.metadata["allowed_push_host"] = "TODO: Set to 'https://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage

  # spec.metadata["source_code_uri"] = "TODO: Put your gem's public repo URL here."
  # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, checkout our
  # guide at: https://bundler.io/guides/creating_gem.html
  spec.add_development_dependency "equivalent-xml", "~> 0.6"
  spec.add_development_dependency "rubocop", "~> 1.23.0"
  spec.add_development_dependency "rubocop-performance", "~> 1.12.0"
  spec.add_development_dependency "rubocop-rails", "~> 2.12.0"
  spec.add_development_dependency "ruby-jing", "~> 0.0.2"
  spec.add_development_dependency "simplecov", "~> 0.21.2"
  spec.add_development_dependency "vcr", "~> 6.0.0"
  spec.add_development_dependency "webmock", "~> 3.14.0"

  spec.add_dependency "mdb", "~> 0.5.0"
  spec.add_dependency "relaton-bib", "~> 1.10.1"
  spec.add_dependency "rubyzip", "~> 2.3.0"
end
