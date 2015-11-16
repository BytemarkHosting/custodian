#
#  The redis-alerter.
#
# This alerter doesn't raise/clear alerts in the traditional sense,
# instead it stores the state of the tests in a Redis store.
#
# We maintain several structures which are updated by raise/clear
# messages.  We keep track of all the recent tests in the set
# `known_tests`.
#
# `known_tests` contains an array of the tests which have been
#  carried out.  For example:
#
#       [ "foo.vm must run ping ..",
#         "bar.vm must run ssh .." ]
#
#  Then for each test we keep track of the state-transitions,
# and do so based upon the SHA1hash of the test-string.
#
#  Assume we have the following test:
#
#     "http://google.com must run http with status 200"
#
#  This is hashed to :
#
#    71cf1735cd389732877177a757c45fdb5407f673
#
#  We then keep the single current-state in the key:
#
#    71cf1735cd389732877177a757c45fdb5407f673.current = pass|fail|unknown
#
#  We build up a history when the state-changes via members of the set
#
#    71cf1735cd389732877177a757c45fdb5407f673.history = [ ]
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
      def initialize(obj)

        begin
          require 'rubygems'
          require 'redis'
          require 'json'

          @redis = Redis.new(:host => @target)

        rescue
          puts 'ERROR Loading redis rubygem!'
        end

        @test  = obj
      end



      #
      # Store an alert in redis
      #
      def raise

        return unless @redis

        #
        #  Make sure we know about this test.
        #
        test_s = @test.to_s

        @redis.sadd( "known_tests", test_s )

        #
        #  Get the current state of this test - so that if the state
        # has changed we can add that to our history.
        #
        #  We use SHA1hash to determine our key.
        #
        key = Digest::SHA1.hexdigest test_s

        #
        #  The current state
        #
        current = @redis.get( "#{key}.current" ) || "unknown"
        @redis.set( "#{key}.current", "FAIL" )

        count = @redis.get( "#{key}.count" ) || "0"
        @redis.set( "#{key}.count", (count.to_i + 1))

        #
        #  Bump the execution count for this test.
        #
        if ( current != "FAIL" )

          #
          #  The state has changed to raise.
          #
          tmp = {}
          tmp['time']   = Time.now.to_i
          tmp['result'] = 'FAIL'
          tmp['reason'] = @test.error

          @redis.lpush( "#{key}.history", tmp.to_json)
          @redis.ltrim('#{key}.history', 0, 100)
        end

      end



      #
      # Clear an alert in redis
      #
      def clear

        return unless @redis

        #
        #  Make sure we know about this test.
        #
        test_s = @test.to_s

        @redis.sadd( "known_tests", test_s )

        #
        #  Get the current state of this test - so that if the state
        # has changed we can add that to our history.
        #
        #  We use SHA1hash to determine our key.
        #
        key = Digest::SHA1.hexdigest test_s

        puts( "Key is #{key}")

        #
        #  The current state
        #
        current = @redis.get( "#{key}.current" ) || "unknown"
        @redis.set( "#{key}.current", "OK" )

        count = @redis.get( "#{key}.count" ) || "0"
        @redis.set( "#{key}.count", (count.to_i + 1 ))

        if ( current != "OK" )

          #
          #  The state has changed to raise.
          #
          tmp = {}
          tmp['time']   = Time.now.to_i
          tmp['result'] = 'OK'
          tmp['reason'] = @test.error

          @redis.lpush( "#{key}.history", tmp.to_json)
          @redis.ltrim('#{key}.history', 0, 100)
        end
      end

      register_alert_type 'redis'

    end
  end
end
