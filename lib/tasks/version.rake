require_relative '../capistrano_docker_compose/version'
task version: ["version:current"]

namespace :version do
  desc "Increment version (optional agument 'major', 'minor', or 'incremental'.  Incremental is the default."
  task :increment, :version_type do |task, args|
    case args[:version_type].to_s
      when 'major'
        puts CapistranoDockerCompose::Version.increment!(type: :major)
      when 'minor'
        puts CapistranoDockerCompose::Version.increment!(type: :minor)
      else
        puts CapistranoDockerCompose::Version.increment!
    end
  end

  task :current do
    puts CapistranoDockerCompose::Version.current
  end

  task :own_current do
    puts CapistranoDockerCompose::Version.own_current
  end
end
