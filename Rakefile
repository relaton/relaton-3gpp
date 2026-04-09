# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

require "rubocop/rake_task"

RuboCop::RakeTask.new

task default: %i[spec]

namespace :spec do
  desc "Download latest 3GPP index fixture from relaton-data-3gpp"
  task :update_index do
    require "net/http"
    require "uri"

    url = "https://raw.githubusercontent.com/relaton/relaton-data-3gpp/data-v2/index-v1.zip"
    dest = File.join(__dir__, "spec", "fixtures", "index-v1.zip")

    puts "Downloading \#{url} ..."
    uri = URI.parse(url)
    response = Net::HTTP.get_response(uri)

    if response.is_a?(Net::HTTPSuccess)
      File.binwrite(dest, response.body)
      puts "Updated \#{dest} (\#{response.body.bytesize} bytes)"
    else
      abort "Failed to download: HTTP \#{response.code}"
    end
  end
end
