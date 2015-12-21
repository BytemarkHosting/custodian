#!/usr/bin/ruby
#
# Add the same three tests over and over again.
#
#
require "redis"

@redis = Redis.new(:host => "127.0.0.1")

x = []

#
# Queue loads of tests
#
(1..10).to_a.each do |i|
  x.push( "test #{i}" )
end

loop do
    x.each do |test|
        @redis.watch('zset')

        print "adding #{test}"

        #
        # This is run in a loop, as we have to wait until both
        #
        # (a) the score is missing
        # (b) the zadd function succeeds
        #
        loop do
          #
          # Print a dot for each go through the loop
          #
          print "."

          #
          # Only update if no score is set
          #
          if !@redis.zscore("zset", test)

            #
            # If MULTI returns nil, the transaction failed, so we need to try
            # again.
            #
            break unless @redis.multi do |r|
              @redis.zadd('zset', Time.now.to_f, test)
            end.nil?

          end

          #
          # This could be tighter..
          #
          sleep 0.1
        end

        print "\n"

        #
        # Do we need to unwatch here?
        #
        @redis.unwatch
    end
end
