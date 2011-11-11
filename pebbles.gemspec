# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "pebbles/version"

Gem::Specification.new do |s|
  s.name        = "pebbles"
  s.version     = Pebbles::VERSION
  s.authors     = ["Katrina Owen", "Simen Svale Skogsrud"]
  s.email       = ["katrina@bengler.no", "simen@bengler.no"]
  s.homepage    = ""
  s.summary     = %q{Development tools for working with Pebbles}
  s.description = %q{Development tools for working with Pebbles}

  s.rubyforge_project = "pebbles"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  s.add_development_dependency "rspec"
  s.add_runtime_dependency "deepstruct"
  s.add_runtime_dependency "rack-streaming-proxy"
  s.add_runtime_dependency "curb"
  s.add_runtime_dependency "yajl-ruby"
  s.add_runtime_dependency "queryparams"
  s.add_runtime_dependency "pathbuilder"
  s.add_runtime_dependency "nokogiri"
  s.add_runtime_dependency "i18n"
  s.add_runtime_dependency "activesupport"
end
