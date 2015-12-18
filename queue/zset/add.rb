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
      puts "adding #{test}"
      @redis.zadd('zset', Time.now.to_i, test)
    end
    sleep 1
end
