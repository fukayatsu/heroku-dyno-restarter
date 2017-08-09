require_relative './test_helper'
require_relative '../web'

class TestWeb < Test::Unit::TestCase
  include Rack::Test::Methods

  setup do
    ENV.store('APP_API_TOKEN', 'valid_token')
  end

  teardown do
    ENV.delete('APP_API_TOKEN')
  end

  def app
    @app ||= Sinatra::Application
  end

  def valid_payload
    # see http://help.papertrailapp.com/kb/how-it-works/web-hooks#example
    @payload ||= {
      events: [
        {
          id: 1234567890,
          source_ip: '127.0.0.1',
          program: 'heroku/web.1',
          message: 'Error R14 (Memory quota exceeded) ',
          received_at: '2017-08-09T06:53:27+09:00',
          display_received_at: 'Aug 09 06:53:27',
          source_id: 2345678901,
          source_name: 'your_app',
          hostname: 'your_app',
          severity: 'Notice',
          facility: 'Syslog'
        }
      ]
    }.to_json
  end

  def test_root
    get '/'
    assert last_response.ok?
  end

  def test_webhook_only_path
    post '/webhook'
    assert last_response.status == 400
    assert last_response.body.match 'invalid api token'
  end

  def test_webhook_with_invalid_token
    post '/webhook', token: 'invalid_token'
    assert last_response.status == 400
    assert last_response.body.match 'invalid api token'
  end

  def test_webhook_without_palyoad
    post '/webhook', token: 'valid_token'
    assert last_response.status == 400
    assert last_response.body.match 'invalid payload'
  end

  def test_webhook_with_invalid_palyoad
    post '/webhook', token: 'valid_token', payload: '{}'
    assert last_response.status == 400
    assert last_response.body.match 'no events'
  end

  def test_webhook_with_valid_palyoad
    any_instance_of(Redis) do |redis|
      mock(redis).get('heroku-dyno-restarter:restarts:your_app:web.1:R14') { false }
    end

    any_instance_of(PlatformAPI::Dyno) do |dyno|
      mock(dyno).restart('your_app', 'web.1') { true }
    end

    post '/webhook', token: 'valid_token', payload: valid_payload
    assert last_response.status == 200
    assert last_response.body.match 'ok'
  end

  def test_webhook_with_valid_palyoad_and_restart_all
    any_instance_of(Redis) do |redis|
      mock(redis).get('heroku-dyno-restarter:restarts:your_app:all:R14') { false }
    end

    any_instance_of(PlatformAPI::Dyno) do |dyno|
      mock(dyno).restart_all('your_app') { true }
    end

    post '/webhook', token: 'valid_token', payload: valid_payload, restart_all: true
    assert last_response.status == 200
    assert last_response.body.match 'ok'
  end
end
