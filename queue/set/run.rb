#!/usr/bin/ruby

require "redis"
require 'pp'
@redis = Redis.new(:host => "127.0.0.1")



def fetch(timeout = 1)
  job = nil

  loop do
    job = @redis.spop('set')

    if !job.nil?
      return job
    else
      sleep(timeout)
    end

  end
end



while( x = fetch() )
  puts "Got job : #{x}"
  if ( x =~ /ping/i )
    puts "PING TEST - sleeping"
    sleep 5
  end
end
