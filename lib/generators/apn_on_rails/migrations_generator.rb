require 'rails/generators/active_record'

module ApnOnRails
  module Generators
    class MigrationsGenerator < Rails::Generators::Base
      include Rails::Generators::Migration
      extend ActiveRecord::Generators::Migration
      
      # Set the current directory as base for the inherited generators.
      def self.base_root
        File.dirname(__FILE__)
      end
      
      source_root File.expand_path('../templates/migrations', __FILE__)
  
      def create_migrations
        # Dir.glob(File.join(self.class.base_root, 'templates', 'migrations', '*.rb')).sort.each do |file|          
        #   migration_template("#{File.basename(file)}", "db/migrate/#{File.basename(file)}");
        # end

        templates = {
          'create_apn_devices.rb' => 'db/migrate/create_apn_devices.rb',
          'create_apn_notifications.rb' => 'db/migrate/create_apn_notifications.rb',
          'create_apn_apps.rb' => 'db/migrate/create_apn_apps.rb',
          'alter_apn_devices.rb' => 'db/migrate/alter_apn_devices.rb',
          'create_groups.rb' => 'db/migrate/create_groups.rb',
          'alter_apn_groups.rb' => 'db/migrate/alter_apn_groups.rb',
          'create_device_groups.rb' => 'db/migrate/create_device_groups.rb',
          'create_apn_group_notifications.rb' => 'db/migrate/create_apn_group_notifications.rb',
          'create_pull_notifications.rb' => 'db/migrate/create_pull_notifications.rb',
          'alter_apn_notifications.rb' => 'db/migrate/alter_apn_notifications.rb',
          'make_device_token_index_nonunique.rb' => 'db/migrate/make_device_token_index_nonunique.rb',
          'add_launch_notification_to_apn_pull_notifications.rb' => 'db/migrate/add_launch_notification_to_apn_pull_notifications.rb',
        }

        templates.each_pair do |name, path|
          begin
            migration_template(name, path)
          rescue => err
            puts "WARNING: #{err.message}"
          end
        end
      end
    end
  end
end
