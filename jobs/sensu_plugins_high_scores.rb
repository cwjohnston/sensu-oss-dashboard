require 'redis-objects'

SCHEDULER.every '5m', :first_in => 0 do |job|
  # excluded_repos = config.fetch("excluded_repos", [])

  excluded_repos =  %w(
    sensu-plugin-spec
    sensu-plugins.github.io
    sensu-plugins-feature-requests
  )

  redis_uri = URI.parse(ENV.fetch("REDISTOGO_URL", "redis://localhost:6379"))

  Redis.current = Redis.new(
    :host => redis_uri.host,
    :port => redis_uri.port,
    :password => redis_uri.password
  )

  plugin_repos = []

  Redis::HashKey.new("github_org_repos:sensu-plugins").each do |name, raw_repo|
    begin
      repo = JSON.parse(raw_repo)
      next if excluded_repos.include?(name)
      plugin_repos << repo
    rescue => e
      puts "#{e}: failed to parse #{raw_repo}"
    end
  end

  plugin_repos.reject! {|repo| repo["batch_score"] == "unknown" }

  top_repos = plugin_repos.sort_by { |record| record["batch_score"] }.reverse[0..9]

  high_scores = top_repos.map do |repo|
    repo.reject! { |k,v| true unless %w( name batch_score time_delta_days ).include?(k) }
  end

  send_event("sensu-plugins-high-scores", {:items => high_scores})
end
