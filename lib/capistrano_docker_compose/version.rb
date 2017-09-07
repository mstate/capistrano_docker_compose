module CapistranoDockerCompose
  require 'yaml'

  class Version
    # def initialize
    #   @yaml = Version.yaml_file
    #   @current_version = (@yaml[:current_version] || "1.0.0")
    # end

    # initialization for class
    puts "defined?(Rails) is: #{defined?(Rails)}"
    if defined?(Rails)
      puts "Rails.root is: #{Rails.root}"
    end
    puts "Dir.pwd is: #{Dir.pwd}"

    if defined?(Rails)
      puts "initializing"
      @@project_root_folder = Rails.root
    else
      @@project_root_folder = Dir.pwd
    end
      puts "@@project_root_folder is: #{@@project_root_folder}"
        puts "full_path is #{[@@project_root_folder,"config","version.yml"].join('/')}"

    def self.increment!(options={})
      options[:type] ||= "incremental"
      hash_from_yaml_file = Version.yaml_file
      version_elements = hash_from_yaml_file[:current_version].split(/\./)
      # last_version_element = version_elements.shift
      case options[:type].to_s
        when "incremental"
          version_elements[2] = (version_elements[2].to_i + 1).to_s
        when "minor" # reset incremental to 0
          version_elements[1] = (version_elements[1].to_i + 1).to_s
          version_elements[2] = 0
        when "major" # reset minor and incremental to 0
          version_elements = [(version_elements[0].to_i + 1).to_s, 0, 0]

      end
      new_version = version_elements.join(".")
      hash_from_yaml_file[:current_version] = new_version
      hash_from_yaml_file[:release_history].unshift({version: new_version, released_at: Time.now})
      Version.update_yaml_file!(hash_from_yaml_file)
      return new_version
    end

    def self.current
      Version.yaml_file[:current_version]
    end

    def self.own_current
      original_project_root = @@project_root_folder
      @@project_root_folder = Dir.pwd
      my_version = self.current
      @@project_root_folder = original_project_root
      return my_version
    end

    def self.replace_version_constant_in_file!(file_path, new_version)
      File.write(file_path, self.new_version)
    end

    def self.yaml_file
      begin
        file = YAML.load_file([@@project_root_folder,"config","version.yml"].join('/'))
      rescue Errno::ENOENT => error
        version_hash = {
          current_version: "1.0.0",
          release_history: [
            {version: "1.0.0", released_at: Time.now}
          ]
        }
        # file doesn't exist.  create it
        Version.update_yaml_file!(version_hash)
        return version_hash
      end
    end

    def self.update_yaml_file!(version_hash)
      File.open([@@project_root_folder,"config","version.yml"].join('/'), 'w') do |f|
        f.write version_hash.to_yaml
      end
    end
  end
end
