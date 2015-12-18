#!/usr/bin/ruby
#
# Add the same three tests over and over again.
#
#
require "redis"

@redis = Redis.new(:host => "127.0.0.1")


x = []

x.push( "http://example.com/ must run http otherwise 'fail'" )
x.push( "1.2.3.4 must run ping otherwise 'fail'" )
x.push( "https://steve.net/ must run https otherwise 'fail'" )


for i in 0 .. 10 
    x.each do |test|
      @redis.sadd('set', test)
    end
end
