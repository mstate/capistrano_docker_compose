require_relative '../capistrano_docker_compose/version'
namespace :version do
  desc "Increment version (optional agument 'major', 'minor', or 'incremental'.  Incremental is the default."
  task :increment, :version_type do |task, args|
    case args[:version_type].to_s
      when 'major'
        CapistranoDockerCompose::Version.increment!(type: :major)
      when 'minor'
        CapistranoDockerCompose::Version.increment!(type: :minor)
      else
        CapistranoDockerCompose::Version.increment!
    end
  end
end
