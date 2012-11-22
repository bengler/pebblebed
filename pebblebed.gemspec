# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "pebblebed/version"

Gem::Specification.new do |s|
  s.name        = "pebblebed"
  s.version     = Pebblebed::VERSION
  s.authors     = ["Katrina Owen", "Simen Svale Skogsrud"]
  s.email       = ["katrina@bengler.no", "simen@bengler.no"]
  s.homepage    = ""
  s.summary     = %q{Development tools for working with Pebblebed}
  s.description = %q{Development tools for working with Pebblebed}

  s.rubyforge_project = "pebblebed"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  s.add_development_dependency "rspec"
  s.add_development_dependency "rake"
  s.add_development_dependency "simplecov"
  s.add_development_dependency "sinatra" # for testing purposes
  s.add_development_dependency "rack-test" # for testing purposes
  s.add_development_dependency "memcache_mock"

  s.add_runtime_dependency "deepstruct", ">= 0.0.2"
  s.add_runtime_dependency "curb", ">= 0.7.14"
  s.add_runtime_dependency "yajl-ruby"
  s.add_runtime_dependency "queryparams"
  s.add_runtime_dependency "futurevalue"
  s.add_runtime_dependency "pathbuilder"
  s.add_runtime_dependency "nokogiri"
  s.add_runtime_dependency "i18n"
  s.add_runtime_dependency "activesupport"
  s.add_runtime_dependency "bunny"

end
