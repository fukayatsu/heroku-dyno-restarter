require 'sinatra'
require 'json'
require 'redis'
require 'heroku-api'

if ENV["REDISCLOUD_URL"]
  $redis = Redis.new(url: ENV["REDISCLOUD_URL"])
else
  $redis = Redis.new
end

$heroku = Heroku::API.new(api_key: ENV['HEROKU_API_KEY'])

get '/' do
  'ok'
end

post '/webhook' do
  return 'invalid api token' unless params[:token] == ENV['APP_API_TOKEN']

  payload     = JSON.parse(params[:payload])
  dyno        = payload['program'].sub(/^heroku\//, '')
  source_name = payload['source_name']
  restart_key = "heroku-dyno-restarter:restarts:#{source_name}:#{dyno}"

  return 'restaring' if $redis.get(restart_key)
  logger.info "[RESTARTING] #{source_name}:#{dyno}"
  $redis.setex(restart_key, 3600, 1)
  $heroku.post_ps_restart(source_name, ps: dyno)

  'ok'
end
