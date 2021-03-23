# encoding: UTF-8
require 'rails/generators'

module Redcap2omop
  class InstallGenerator < Rails::Generators::Base
    class_option 'migrations', type: :boolean
    class_option 'config', type: :boolean
    class_option 'migrate', type: :boolean

    def self.source_paths
      paths = self.superclass.source_paths
      paths << File.expand_path('../templates', __FILE__)
      paths.flatten
    end

    desc 'Used to install redcap2omop.'

    def copy_omop_data_model_files
      unless options['omop_data_model'] == false
        puts 'Copying over OMOP data model files...'
        source_path = "#{File.expand_path('../templates', __FILE__)}/data_models/"
        destination_path = "#{Rails.root}/db/migrate"
        FileUtils.copy_entry source_path, destination_path
      end
    end

    def install_migrations
      unless options['migrations'] == false
        puts 'Copying over redcap2omop migrations...'
        Dir.chdir(Rails.root) do
          `rake redcap2omop:install:migrations`
        end
      end
    end

    def install_config_files
      unless options['config'] == false
        puts 'Copying over redcap2omop configuration files ...'
        copy_file 'initializers/redcap2omop.rb', "#{Rails.root}/config/initializers/redcap2omop.rb"
      end
    end

    def run_migrations
      unless options['migrate'] == false
        puts "Running rake db:migrate"
        `rake db:migrate`
      end
    end
  end
end
