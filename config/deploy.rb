# -*- encoding : utf-8 -*-
$:.unshift(File.expand_path('./lib', ENV['rvm_path']))
require "rvm/capistrano"

#set :rvm_bin_path, "/usr/local/rvm/bin"
set :rvm_ruby_string, '1.9.3@twackr'
set :rvm_type, :user

require 'bundler/capistrano'

set :application, "twackr"
#set :rails_env, "production"
set :rails_env, "development"

set :scm, :git
set :repository, "https://github.com/dexion/twackr.git"
set :branch, "master"

set :deploy_to, "/var/www/twackr"
#set :deploy_via, :remote_cache
set :keep_releases, 3

role :web, "176.58.104.134"                          # Your HTTP server, Apache/etc
role :app, "176.58.104.134"                          # This may be the same as your `Web` server
role :db,  "176.58.104.134", :primary => true        # This is where Rails migrations will run

set :user, 'snake'
set :use_sudo, false

set :unicorn_conf, "#{deploy_to}/current/config/unicorn.rb"
set :unicorn_pid, "#{deploy_to}/shared/pids/unicorn.pid"


# If you are using Passenger mod_rails uncomment this:
 namespace :deploy do
  task :restart do
    #run "touch #{deploy_to}/current/tmp/restart.txt" #не хочет он так по номральному стартовать
    #run "cd #{deploy_to}/current && passenger stop && passenger start -d"
    # for unicorn uncomment:
    run "if [ -f #{unicorn_pid} ]; then kill -USR2 `cat #{unicorn_pid}`; else cd #{deploy_to}/current && bundle exec unicorn_rails -c #{unicorn_conf} -E #{rails_env} -D; fi"
  end
  task :start do
    #run "cd #{deploy_to}/current && passenger start -d"
    # for unicorn uncomment:
    run "cd #{deploy_to}/current && bundle exec unicorn_rails -c #{unicorn_conf} -E #{rails_env} -D"
  end
  task :stop do
    # run "cd #{deploy_to}/current && passenger stop"
    # for unicorn uncomment:
    run "if [ -f #{unicorn_pid} ]; then kill -QUIT `cat #{unicorn_pid}`; fi"
  end
end

namespace :unicorn do
  task :restart do
    run "if [ -f #{unicorn_pid} ]; then kill -USR2 `cat #{unicorn_pid}`; else cd #{deploy_to}/current && bundle exec unicorn_rails -c #{unicorn_conf} -E #{rails_env} -D; fi"
  end
  task :start do
    run "cd #{deploy_to}/current && bundle exec unicorn_rails -c #{unicorn_conf} -E #{rails_env} -D"
  end
  task :stop do
    run "if [ -f #{unicorn_pid} ]; then kill -QUIT `cat #{unicorn_pid}`; fi"
  end
end

namespace :bundler do
  task :create_symlink, :roles => :app do
    shared_dir = File.join(shared_path, 'bundle')
    release_dir = File.join(current_release, '.bundle')
    run("mkdir -p #{shared_dir} && ln -s #{shared_dir} #{release_dir}")
  end

  task :bundle_new_release, :roles => :app do
    bundler.create_symlink
    run "cd #{release_path} && bundle install --without development test"
  end
end

namespace :deploy do
  task :config_db_yaml do
    run "rm -f #{current_release}/config/database.yml && ln -s #{shared_path}/config/database.yml #{current_release}/config/database.yml"
  end
  
  task :precompiled do
    run "cd #{release_path} && bundle exec rake assets:precompile"
  end
  
end

after 'deploy:update_code', 'bundler:bundle_new_release'
after 'deploy:update_code', 'deploy:config_db_yaml'
#after 'deploy:update_code', 'deploy:precompiled'

