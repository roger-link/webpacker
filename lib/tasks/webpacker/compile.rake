require "open3"
require "webpacker/env"
require "webpacker/configuration"

namespace :webpacker do
  desc "Compile javascript packs using webpack for production with digests"
  task compile: ["webpacker:verify_install", :environment] do
    $stdout.puts "[Webpacker] Compiling assets 🎉"
    $stdout.puts "Asset Host:"
    asset_host = ActionController::Base.helpers.compute_asset_host
    $stdout.puts "\e[31m#{asset_host}\e[0m"
    $stdout.puts "Node ENV:"
    $stdout.puts "\e[31m#{Webpacker.env}\e[0m"
    env = { "NODE_ENV" => Webpacker.env, "ASSET_HOST" => asset_host }.freeze
    $stdout.puts "ENV:"
    $stdout.puts "\e[31m#{env}\e[0m"

    $stdout.puts "Calling Open3"
    system "./bin/webpack"
    stdout_str, stderr_str, status = Open3.capture3(env, "./bin/webpack")
    $stdout.puts "Open3 Called"
    $stdout.puts "Status:"
    $stdout.puts "\e[31m#{status}\e[0m"
    $stdout.puts "Standard Error:"
    $stdout.puts "\e[31m#{stderr_str}\e[0m"
    $stdout.puts "Standard Out:"
    $stdout.puts "\e[31m#{stdout_str}\e[0m"

    if status.success?
      $stdout.puts "\e[32m[Webpacker] Compiled digests for all packs in #{Webpacker::Configuration.entry_path}:\e[0m"
      $stdout.puts "\e[32m#{JSON.parse(File.read(Webpacker::Configuration.manifest_path))}\e[0m"
    else
      $stdout.puts "[Webpacker] Compilation Failed"
      $stdout.puts "\e[31m#{stdout_str}\e[0m"
      $stderr.puts "\e[31m#{stderr_str}\e[0m"
      exit!
    end
  end
end

# Compile packs after we've compiled all other assets during precompilation
if Rake::Task.task_defined?("assets:precompile")
  Rake::Task["assets:precompile"].enhance do
    unless Rake::Task.task_defined?("yarn:install")
      # For Rails < 5.1
      Rake::Task["webpacker:yarn_install"].invoke
    end
    Rake::Task["webpacker:compile"].invoke
  end
end
