# rvm setup

$:.unshift(File.expand_path('./lib', ENV['rvm_path'])) # Add RVM's lib directory to the load path.
require "rvm/capistrano"                  # Load RVM's capistrano plugin.
set :rvm_ruby_string, '1.9.3'        # Or whatever env you want it to run in.

# application setup

set :application, "btlshp"
set :repository,  "git://github.com/madisp/Btlshp.git"

set :scm, :git

role :web, "btlshp.madisp.com"
role :app, "btlshp.madisp.com"
role :db,  "btlshp.madisp.com", :primary => true

set :user, 'ubuntu'
set :use_sudo, false
set :deploy_to, '/var/www/btlshp'
set :deploy_via, :remote_cache

ssh_options[:forward_agent] = false

# Passenger restart
namespace :deploy do
  task :start do ; end
  task :stop do ; end
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
  end
end

require 'pathname'

namespace :security do
  namespace :symlinks do
    task :setup, :roles => [:app, :web], :except => { :no_release => true } do
      run "touch #{shared_path}/secret_token.rb"
    end
    task :update, :roles => [:app, :web], :except => { :no_release => true } do
      orig = "#{release_path}/config/initializers/secret_token.rb"
      run "rm #{orig}"
      run "ln -nfs #{shared_path}/secret_token.rb #{orig}"
    end
  end
end

namespace :ci do
  task :append_version, :roles => [:app, :web], :except => { :no_release => true } do
    env_version = ENV['BUILD_VERSION']
    if env_version
      version = env_version.gsub /[^0-9\.A-z\-\_]/, ''
      if version and version.length > 0
        run "echo '#{version}' > #{release_path}/.build_version"
      end
    end
  end
end

before 'deploy:setup' do
  security.symlinks.setup
end

before 'deploy:symlink' do
  security.symlinks.update
  ci.append_version
end
