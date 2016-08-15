# Sensu Plugins Dashboard

## What is this?

This dashboard is meant to help [Sensu Plugins Project][1] maintainers keep an eye on the
overall status of the project'st various plugin collections shipped as gems.

Check out http://shopify.github.com/dashing for more information on the
underlying dashboard framework.

## How do I run this locally?

You'll need a Github oauth2 token and a Redis server to run the dashboard jobs.

1. bundle install
1. export GITHUB_ACCESS_TOKEN and REDISTOGO_URL env vars appropriately
1. bundle dashing start

### How do I deploy this?

Currently deployed to Heroku via git push.

[1]: http://sensu-plugins.io/