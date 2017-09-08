class RakeGem::Railtie < Rails::Railtie
  rake_tasks do
    load 'tasks/docker_compose.rake'
  end
end
