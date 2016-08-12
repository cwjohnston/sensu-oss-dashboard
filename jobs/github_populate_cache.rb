require 'redis-objects'
require 'octokit'
require 'yaml'

config = YAML::load_file('github.yml')

Octokit.configure do |c|
  c.auto_paginate = true
end

@client = Octokit::Client.new(:access_token => ENV.fetch("GITHUB_ACCESS_TOKEN", ""))
redis_uri = URI.parse(ENV.fetch("REDISTOGO_URL", "redis://localhost:6379"))

Redis.current = Redis.new(
  :host => redis_uri.host,
  :port => redis_uri.port,
  :password => redis_uri.password
)

SCHEDULER.every '20m', :first_in => 0 do |job|
  @org_repos = Redis::HashKey.new("github_org_repos:sensu-plugins")
  @client.org_repos("sensu-plugins").each do |repo_resource|
    begin
      repo = repo_resource.to_hash
      qualified_repo_name = "sensu-plugins/#{repo[:name]}"
      latest_release = @client.latest_release(qualified_repo_name)
      commit_count = @client.commits_since(qualified_repo_name, latest_release.attrs[:published_at]).count
      time_delta_days = (Time.now.to_date - latest_release.attrs[:published_at].to_date).round
      batch_score = time_delta_days * commit_count
      repo.merge!({ :batch_score => batch_score, :time_delta_days => time_delta_days })
      @org_repos[repo[:name]] = repo.to_json
    rescue => e
      puts "error lol: #{qualified_repo_name} #{e}"
      repo.merge!({ :batch_score => 'unknown', :time_delta_days => time_delta_days })
      @org_repos[repo[:name]] = repo.to_json
    end
  end
end
