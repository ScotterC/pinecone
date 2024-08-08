require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

task default: :spec

require_relative "spec/support/index_helpers"

namespace :indices do
  desc "Clear indices"
  task :clear do
    IndexHelpers.clear_indices
    IndexHelpers.print_index_counts
  end

  desc "Print index counts"
  task :counts do
    IndexHelpers.print_index_counts
  end

  desc "Start indices"
  task :start do
    IndexHelpers.start_indices
  end

  desc "Stop indices"
  task :stop do
    IndexHelpers.stop_indices
  end
end
