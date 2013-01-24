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

    class RedisAlert < AlertFactory


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

        begin
          require 'rubygems'
          require 'redis'

          @redis = Redis.new(:host => @target )

        rescue
          puts "ERROR Loading redis rubygem!"
        end

        @test  = obj
      end



      #
      # Store an alert in redis
      #
      def raise

        return unless( @redis )


        # hostname + test-type
        host = @test.target
        test = @test.get_type

        # store the error - set an expiry time of 5 minutes
        @redis.set( "#{host}-#{test}", "ERR")
        @redis.expireat( "#{host}-#{test}", Time.now.to_i + 5 * 60 )

        # Set the reason
        @redis.set( "#{host}-#{test}-reason", @test.error() )
        @redis.expireat( "#{host}-#{test}-reason", Time.now.to_i + 5 * 60 )

        # make sure this alert is discoverable
        @redis.sadd( "hosts", "#{host}-#{test}" )
      end



      #
      # Clear an alert in redis
      #
      def clear

        return unless( @redis )


        # hostname + test-type
        host = @test.target
        test = @test.get_type

        # store the OK - set the expiry time of five minutes
        @redis.set( "#{host}-#{test}", "OK")
        @redis.expireat( "#{host}-#{test}", Time.now.to_i + 5 * 60 )

        # clear the reason
        @redis.set( "#{host}-#{test}-reason", "")
        @redis.expireat( "#{host}-#{test}-reason", Time.now.to_i + 5 * 60 )


        # make sure this alert is discoverable
        @redis.sadd( "hosts", "#{host}-#{test}" )
      end



      #
      # Store a test-duration in redis
      #
      def duration( ms )

        return unless( @redis )

        #
        # hostname + test-type
        #
        host = @test.target
        test = @test.get_type

        #
        # Store the host.
        #
        # make sure this alert is discoverable
        @redis.sadd( "duration-hosts", host )

        #
        # Store the test.
        #
        @redis.sadd( "duration-host-#{host}", test )

        #
        # Now store the duration, and trim it to the most recent
        # 1000 entries.
        #
        @redis.lpush( "#{host}-#{test}", ms )
        @redis.ltrim( "#{host}-#{test}", "0", "1200" )
      end

      register_alert_type "redis"




    end
  end
end
