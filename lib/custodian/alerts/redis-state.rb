
require 'rubygems'
require 'redis'


#
#  The redis-alerter.
#
#  This doesn't raise/clear alerts in the traditional sense, instead it just
# stores results in a redis database where you can poll them from a status-panel,
# or similar.
#
#  There is a global set called "hosts" which has the hostname-test-type lists
# and the individual results can be pulled by simple key-fetches on those.
#
module Custodian

  module Alerter

    class AlertRedis < AlertFactory

      #
      # The test this alerter cares about
      #
      attr_reader :test

      #
      # The redis-object
      #
      attr_reader :redis


      #
      # Constructor - save the test-object away & instantiate
      # the redis connection.
      #
      def initialize( obj )
        @test = obj
        @redis = Redis.new
      end



      #
      # Store an alert in redis
      #
      def raise

        # hostname + test-type
        host = @test.target
        test = @test.get_type

        # store the error
        @redis.set( "#{host}-#{test}", "ERR")
        @redis.set( "#{host}-#{test}-reason", @test.error() )

        # make sure this alert is discoverable
        @redis.sadd( "hosts", "#{host}-#{test}" )
      end



      #
      # Clear an alert in redis
      #
      def clear

        # hostname + test-type
        host = @test.target
        test = @test.get_type

        # store the OK
        @redis.set( "#{host}-#{test}", "OK")
        @redis.set( "#{host}-#{test}-reason", "")

        # make sure this alert is discoverable
        @redis.sadd( "hosts", "#{host}-#{test}" )
      end



      register_alert_type "redis"




    end
  end
end
