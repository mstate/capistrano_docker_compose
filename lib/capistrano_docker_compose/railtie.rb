class CapistranoDockerCompose::Railtie < Rails::Railtie
  rake_tasks do
    load '../capistrano/tasks/docker_compose.rake'
  end
end
