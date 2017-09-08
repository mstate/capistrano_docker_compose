class CapistranoDockerCompose::Railtie < Rails::Railtie
  rake_tasks do
    puts "pwd: #{Dir.pwd}"
    load '../capistrano/tasks/docker_compose.rake'
  end
end
