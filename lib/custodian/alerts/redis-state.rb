#
#  The redis-alerter.
#
#  This doesn't raise/clear alerts in the traditional sense, instead
# it just saves the results in a "recent tests" set inside Redis.
#
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
          require 'json'

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

        tmp = {}
        tmp["time"] = Time.now.to_i
        tmp["type"] = @test.get_type
        tmp["target"] = @test.target
        tmp["result"] = "RAISE"
        tmp["reason"] =  @test.error()

        @redis.lpush( "recent-tests", tmp.to_json)
        @redis.ltrim( "recent-tests", 0, 100 )

      end



      #
      # Clear an alert in redis
      #
      def clear

        return unless( @redis )


        tmp = {}
        tmp["time"]   = Time.now.to_i
        tmp["type"]   = @test.get_type
        tmp["target"] = @test.target
        tmp["result"] = "OK"
        tmp["reason"] = ""

        @redis.lpush( "recent-tests", tmp.to_json)
        @redis.ltrim( "recent-tests", 0, 100 )
      end



      #
      # Store a test-duration in redis
      #
      def duration( ms )

        return unless( @redis )

        # NOP
      end


      register_alert_type "redis"

    end
  end
end
