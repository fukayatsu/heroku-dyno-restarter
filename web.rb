require 'sinatra'
require 'json'
require 'redis'
require 'platform-api'

REDIS  = Redis.new(url: ENV['REDIS_URL'] || ENV["REDISCLOUD_URL"])
HEROKU = PlatformAPI.connect(ENV['HEROKU_API_KEY'])
RESTART_INTERVAL = (ENV['RESTART_INTERVAL'] || 1800).to_i

get '/' do
  'ok'
end

post '/webhook' do
  return bad_request('invalid api token') unless params[:token] == ENV['APP_API_TOKEN']
  return bad_request('invalid payload') unless params[:payload]

  restart_all = !!params[:restart_all]
  payload     = JSON.parse(params[:payload]||'{}')
  events      = payload.dig('events')

  return bad_request('no events') unless events

  logger.info "[webhook events] #{events}"

  events.each do |event|
    message = event['message']
    program = event['program']
    dyno    = message.scan(/\sdyno=(\S+)\s/).flatten[0] || program.scan(/(?:heroku|app)\/(\S+)/).flatten[0]
    error_code = message.scan(/\scode=(\S+)\s/).flatten[0] || message.scan(/Error (\S+)\s/).flatten[0] || 'unknown'
    unless dyno.to_s.match(/web/)
      logger.info "[skip] non web dyno: #{dyno}"
      next
    end

    source_name = ENV['SOURCE_APP_NAME'] || event['source_name']
    if restart_all
      restart_key = "heroku-dyno-restarter:restarts:#{source_name}:all:#{error_code}"
    else
      restart_key = "heroku-dyno-restarter:restarts:#{source_name}:#{dyno}:#{error_code}"
    end
    if REDIS.get(restart_key)
      logger.info "[skip] restart_key exists: #{restart_key} for #{REDIS.ttl(restart_key)}"
      next
    end

    REDIS.setex(restart_key, RESTART_INTERVAL, 1)
    if restart_all
      logger.info "[RESTARTING] #{source_name}:all by #{error_code}: #{message}"
      HEROKU.dyno.restart_all(source_name)
    else
      logger.info "[RESTARTING] #{source_name}:#{dyno} by #{error_code}: #{message}"
      HEROKU.dyno.restart(source_name, dyno)
    end
    logger.info "done restarting."
  end

  'ok'
end

def bad_request(body)
  status 400
  body
end
