#!/usr/bin/ruby
#
# Add the same three tests over and over again.
#
#
require "redis"

@redis = Redis.new(:host => "127.0.0.1")


x = []

x.push( "test 1" )
x.push( "test 2" )
x.push( "test 3" )


for i in 0 .. 10 
    x.each do |test|
        @redis.watch('zset')
        if (!(@redis.zscore("zset", test)))
            res = @redis.multi do |r|
                r.zadd('zset', Time.now.to_f * 10000000, test)
            end
        end
        @redis.unwatch
    end
    sleep 1
end
