require 'sinatra'
require 'json'
require 'redis'
require 'heroku-api'

REDIS  = Redis.new(url: ENV["REDISCLOUD_URL"])
HEROKU = Heroku::API.new(api_key: ENV['HEROKU_API_KEY'])
RESTART_INTERVAL = (ENV['RESTART_INTERVAL'] || 1800).to_i

get '/' do
  'ok'
end

post '/webhook' do
  return 'invalid api token' unless params[:token] == ENV['APP_API_TOKEN']

  payload     = JSON.parse(params[:payload])
  events      = payload['events']

  logger.info "[webhook events] #{events}"

  events.each do |event|
    dyno = event['program'].sub(/^heroku\//, '')
    unless dyno.match(/web/)
      logger.info "[skip] non web dyno: #{dyno}"
      next
    end

    source_name = event['source_name']
    restart_key = "heroku-dyno-restarter:restarts:#{source_name}:#{dyno}"

    if REDIS.get(restart_key)
      logger.info "[skip] restart_key exists: #{restart_key} for #{REDIS.ttl(restart_key)}"
      next
    end

    REDIS.setex(restart_key, RESTART_INTERVAL, 1)
    logger.info "[RESTARTING] #{source_name}:#{dyno}"
    HEROKU.post_ps_restart(source_name, ps: dyno)
    logger.info "done restarting."
  end

  'ok'
end
