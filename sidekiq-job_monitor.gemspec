$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "sidekiq/job_monitor/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "sidekiq-job_monitor"
  s.version     = Sidekiq::JobMonitor::VERSION
  s.authors     = ["vala"]
  s.email       = ["vala@glyph.fr"]
  s.homepage    = "https://github.com/glyph-fr/sidekiq-job_monitor"
  s.summary     = "Monitor currently running Sidekiq jobs to give user feedback"
  s.description = "Monitor currently running Sidekiq jobs to give user feedback"
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "rails", "~> 4.0"
  s.add_dependency "sidekiq", "~> 4.0"
end
