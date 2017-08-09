ENV['RACK_ENV'] ||= 'test'

require 'bundler/setup'
require 'test/unit'
require 'test/unit/rr'
require 'rack/test'
