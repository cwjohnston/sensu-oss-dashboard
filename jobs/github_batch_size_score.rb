require 'octokit'

config = YAML::load_file('github.yml')

Octokit.configure do |c|
  c.auto_paginate = true
end

@client = Octokit::Client.new(:access_token => ENV.fetch("GITHUB_ACCESS_TOKEN", ""))

SCHEDULER.every '1m', :first_in => 0 do |job|

  compare_time = Time.now

  config["repos"].each do |name|
    latest_release = @client.latest_release(name)
    seconds_since_last_release = compare_time - latest_release.attrs[:published_at]
    commits = @client.commits_since(
      name, latest_release.attrs[:published_at]
    )

    commit_count = commits.count
    time_delta_days = (Time.now.to_date - latest_release.attrs[:published_at].to_date).round
    batch_score = time_delta_days * commits.count

    send_event(name, {
      :repo => name,
      :commits_since_last_release => commits.count,
      :days_since_last_release => time_delta_days,
      :batch_score => batch_score
    })
  end
end
