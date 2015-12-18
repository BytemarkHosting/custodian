#!/usr/bin/ruby

require "redis"
require 'pp'
@redis = Redis.new(:host => "127.0.0.1")



def fetch(timeout = 1)
  job = nil

  loop do
    job = @redis.ZREVRANGE('zset', '0', '0')

    if !job.empty?
      # We only have one entry in our array
      job = job[0]

      # Remove from the queue
      @redis.zrem('zset', job );

      return job
    else
      sleep(timeout)
    end

  end
end

seen = []

while( x = fetch() )
  puts "Got job : #{x}"
  if seen.include?(x)
    puts "Already seen #{x}"
    break
  end

  seen << x

  if ( x =~ /test 2/i )
    puts "TEST 2 - sleeping"
    sleep 5
  end
end
