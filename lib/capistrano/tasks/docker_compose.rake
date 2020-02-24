require 'dotenv'
Dotenv.load('.env')

namespace :docker do
  desc "Increment application version number"
  task :increment_version do
    puts CapistranoDockerCompose::Version.increment!
    # run_locally do
    # end
  end

  desc "upload files, build images, and start containers for first deployment"
  task :first_deploy, :app_version do |task, args|
    Rake::Task["docker:set_registry_link_with_version"].invoke(args)
    run_locally do
      # with rails_env: fetch(:rails_env) do
        Rake::Task["docker:build"].invoke(args)
        Rake::Task["docker:setup"].invoke(args)
        Rake::Task["docker:update_images"].invoke(args)
        Rake::Task["docker:createdb"].invoke
        Rake::Task["docker:migrate"].invoke(args) unless fetch(:skip_migration)
        Rake::Task["docker:restart"].invoke(args)
      # end
    end
  end

  desc "build and deploy"
  task :deploy, :app_version do |task, args|
    Rake::Task["docker:set_registry_link_with_version"].invoke(args)
    run_locally do
      Rake::Task["docker:build"].invoke(args)
      Rake::Task["docker:update_images"].invoke(args)
      Rake::Task["docker:migrate"].invoke(args) unless fetch(:skip_migration)
      Rake::Task["docker:quick_restart"].invoke(args)
    end
  end

  desc "Checkout specified version or latest from Git and use that director for deploy."
  task :grab_from_git, :app_version do |task, args|
    run_locally do
      if Dir.exist?(fetch(:git_cache_folder)) && Dir.exist?("#{fetch(:git_cache_folder)}/.git")
        within fetch(:git_cache_folder) do
          execute :git, "fetch --all"
          execute :git, "checkout origin/#{fetch(:branch, "master")}"
          # execute :git, :pull
          execute :git, "reset --hard" # origin/#{fetch(:branch, "master")}"
          execute :git, "clean -d -x -f"
        end
      # else, create it and checkout
      else
        execute :mkdir, "-p #{fetch(:git_cache_folder)}"
        within fetch(:git_cache_folder) do
          execute :git, "clone #{fetch(:repository)} ."
          execute :git, "checkout origin/#{fetch(:branch, "master")}"
        end
      end

      # if there's an env file, link it
      if File.exists?('.env')
        within fetch(:git_cache_folder) do
          number_of_folders_to_ascend = fetch(:git_cache_folder).split('/').length
          ascend_array = []
          number_of_folders_to_ascend.to_i.times{ ascend_array << '..' }
          ascend_path = ascend_array.join('/')
          execute :cp, "#{ascend_path}/.env .env"
        end
      end

      # copy any files not checked in from main repo
      (fetch(:files_required_for_build) || []).each do |file_name|
        # if the file_name contains a directory, create it if needed
        if file_name =~ /\//
          file_name_array = file_name.split(/\//)
          file_name_array.pop # remove the file_name
          file_path = file_name_array.join("/")
          unless Dir.exist? "#{fetch(:git_cache_folder)}/#{file_path}"
            execute :mkdir, "-p", file_path
          end
        end
        # --parents creates the path if it doesn't exist
        execute :cp, file_name, "#{fetch(:git_cache_folder)}/#{file_name}"
      end
    end
  end

  desc "setup folder structure for volumes"
  task :setup do
    fetch(:docker_compose_files).each do |file|
      yaml = YAML.load_file(file)
      yaml["services"]&.keys&.each do |service|
        (yaml["services"][service]["volumes"] || []).each do |volume|
          volume_array = volume.split(/:/)
          if volume_array.length > 1
            server_folder = volume_array[0].gsub('${DEPLOY_TO_DIRECTORY}', deploy_to)
            on roles :app do
              execute :mkdir, "-p #{server_folder}"
            end
          end
        end
      end
    end
  end

  desc "create database"
  task :createdb do
    on roles :app do
      within deploy_to do
        execute :"docker-compose", "run -d db"
        # give the db a chance to initialize
        # it will create the user and database based on .env file data
        execute :echo, "'Sleeping for 30 seconds to allow initialization of user and database...'"
        sleep 30
        execute :"docker-compose", "down"
      end
    end
  end

  desc "run database migrations"
  task :migrate, :app_version do |task, args|
    Rake::Task["docker:set_registry_link_with_version"].invoke(args)
    on roles :app do
      within deploy_to do
        execute :"docker-compose", 'down'
        execute :"docker-compose", "up -d #{fetch(:docker_database_service_name)}"
        # should take the environment from the docker-compose file
        # run is used instead of exec just in case the app fails to start
        # due to a migration that has not yet run (e.g. a data migration)
        execute :"docker-compose", "run --rm #{fetch(:docker_migrate_app_service_name)} rake db:migrate"
      end
    end
  end

  desc "Full restart of all services in the docker-compose file"
  task :quick_restart do
    on roles :app do
      within deploy_to do
        execute :"docker-compose", "up -d "
      end
    end
  end

  desc "Full restart of all services in the docker-compose file"
  task :full_restart do
    on roles :app do
      within deploy_to do
        execute :"docker-compose", "up -d --force-recreate"
      end
    end
  end

  desc "Full restart of all services in the docker-compose file"
  task :restart do
    on roles :app do
      within deploy_to do
        # force recreate shouldn't be necessary
        # but sometime Traefik misses something
        # and the service disappears after auto restart
        # with new image.  So, added a force-recreate to see if it helps
        execute :"docker-compose", "up -d --force-recreate #{fetch(:docker_services_for_quick_restart).join(' ')}"
      end
    end
  end

  desc "Full restart of all services in the docker-compose file"
  task :restart_traefik do
    on roles :app do
      if fetch(:traefik_directory)
        within fetch(:traefik_directory) do
          execute :"docker-compose", :up, "-d", "--force-recreate"
        end
      end
    end
  end


  desc "pull latest images"
  task :update_images, :app_version do |task, args|
    Rake::Task["docker:set_registry_link_with_version"].invoke(args)

    # copy the docker-compose.yml and docker-compose.prod.yml to production

    ##############################
    ##### make a single docker-compose.yml file, upload it and delete it

    # combine docker-compose files into one file
    yamls = []
    fetch(:docker_compose_files).each do |file|
      yamls << YAML.load_file(file)
    end

    # merge files in order
    consolidated_yaml = {}
    while yamls.length > 0
      consolidated_yaml.merge_docker_hash! yamls.shift
    end

    # replace versions with current in combined file
    consolidated_yaml["services"].keys.each do |service|
      if fetch(:docker_web_service_name) && service == fetch(:docker_web_service_name)
        consolidated_yaml["services"][fetch(:docker_web_service_name)]["image"] = fetch(:docker_web_registry_link_with_version)
      else
        # if it's using the same image as app, update it with app
        base_registry_image = fetch(:docker_app_registry_link_with_version).split(/:/)[0]

        # Macro substitution to keep docker-compose.prod.yml file generic        
        docker_app_registry_link_from_file = consolidated_yaml.dig('services', service, 'image')&.
          gsub(/\${APPLICATION_NAME}/, fetch(:application))&.
          gsub(/\${APP_VERSION:-latest}/, args[:app_version] || CapistranoDockerCompose::Version.current)
          
        # if it's using the same image as app, update it with app
        if  docker_app_registry_link_from_file =~ /#{base_registry_image}/
          consolidated_yaml["services"][service]["image"] = fetch(:docker_app_registry_link_with_version)
        end      
      end
    end

    # write the consolidated file
    File.open("docker-compose.combined.prod.yml", 'w') do |f|
      f.write consolidated_yaml.to_yaml
    end

    # upload consolidated file
    on roles :app do
      upload! "docker-compose.combined.prod.yml", [deploy_to, "docker-compose.yml"].join('/')
    end

    # delete consolidated file
    sh "rm docker-compose.combined.prod.yml"


    ##############################
    ###### pull the latest images
    on roles :app do
      within deploy_to do
        # with rails_env: fetch(:rails_env) do
        # execute 'eval "$(cat /docker/compose_files_and_data/srcanada-staging/.env | grep REGISTRY_)"'
        # execute "source #{deploy_to}/.env; docker login -u $REGISTRY_USER -p $REGISTRY_PASS #{fetch(:registry)}"
        execute ''
        execute "eval \"$(cat #{deploy_to}/.env | grep REGISTRY_)\";" \
          + " docker login -u $REGISTRY_USER -p $REGISTRY_PASS #{fetch(:registry)}"
        execute :pwd
        execute :"docker-compose", :pull
        # end
      end
    end
  end

  desc "build and check-in images"
  task :build, :app_version do |task, args|
    # start by updating from Git
    Rake::Task["docker:set_registry_link_with_version"].invoke(args)
    Rake::Task["docker:grab_from_git"].invoke(args)

    run_locally do
      within fetch(:git_cache_folder) do
        git_cache_absolute_folder = capture('pwd')

        execute :docker, "login -u $REGISTRY_USER -p $REGISTRY_PASS #{fetch(:registry)}"

        # build app with pre-compiled assets
        execute :docker, "build -f #{fetch(:docker_app_dockerfile)} -t #{fetch(:docker_app_registry_link_with_version)} ."

        # mount the
        # check-in NGINX server image to registry
        if fetch(:docker_web_service_name)
          # Build the NGINX server
          raise "Must specify docker_web_dockerfile" unless fetch(:docker_web_dockerfile)
          # grab the compiled assets from the app image

          execute :rm, "-fR deleteme"
          execute :mkdir, "-p deleteme"
          container_name = Time.now.to_i
          execute :docker, "create --name #{container_name} #{fetch(:docker_app_registry_link_with_version)}"

          # copy compiled assets to local folder
          if system("docker run #{fetch(:docker_app_registry_link_with_version)} ls /app/public")
            execute :docker, "cp #{container_name}:/app/public/ ./deleteme/"
          end
          execute :docker, "rm -v #{container_name}"

          # build and tag
          execute :docker, "build -f #{fetch(:docker_web_dockerfile)} -t #{fetch(:docker_web_registry_link_with_version)} #{git_cache_absolute_folder}"

          # remove pre-compiled assets
          # execute :rm, "-fR tmp/public"

          execute :docker, "push #{fetch(:docker_web_registry_link_with_version)}"
        end

        # check-in rails image
        execute :docker, "push #{fetch(:docker_app_registry_link_with_version)}"

        # build other services
        yamls = []
        fetch(:docker_compose_files).each do |file|
          yamls << YAML.load_file(file)
        end
        consolidated_yaml = {}
        while yamls.length > 0
          consolidated_yaml.merge_docker_hash! yamls.shift
        end

      end
    end
  end

  desc "set registry link with version variables"
  task :set_registry_link_with_version do |task, args|
    puts "received args #{args} with app version '#{args[:app_version]}'"
    docker_image_version = args[:app_version] || CapistranoDockerCompose::Version.current
    puts "docker_image_version is #{docker_image_version}"
    set :docker_app_registry_link_with_version, "#{fetch(:docker_app_registry_link)}:#{docker_image_version}"
    if fetch(:docker_web_service_name)
      set :docker_web_registry_link_with_version, "#{fetch(:docker_web_registry_link)}:#{docker_image_version}"
    end
  end
end

# Set default values
namespace :load do
  task :defaults do
    set :docker_app_service_name, "app"
    set :docker_web_service_name, "web"
    set :docker_database_service_name, "db"
    set :docker_app_dockerfile, "Dockerfile.prod"
    set :docker_web_dockerfile, "Dockerfile.prod.nginx"

    set :docker_compose_files, %w{docker-compose.yml docker-compose.prod.yml}
    set :registry, 'registry.modus-ops.com'
    set :docker_web_registry_link, "#{fetch(:registry)}/#{fetch(:application)}/web"
    set :docker_app_registry_link, "#{fetch(:registry)}/#{fetch(:application)}/app"
    set :branch, "master"
    set :git_cache_folder, "tmp/git_cache_for_deploy"
    set :docker_services_for_quick_restart, %w{ app actioncable sidekiq web }
    set :traefik_directory, "/docker/compose_files_and_data/traefik"
    set :skip_migration, false
    set :docker_migrate_app_service_name, fetch(:docker_app_service_name)
  end
end
