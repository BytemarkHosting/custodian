
#!/usr/bin/ruby

require "redis"
require 'pp'

class Arse

  def initialize(name)
    @name = name
    @redis = Redis.new(:host => "127.0.0.1")
  end

  def fetch(timeout = 1)
    loop do
      job = nil
      @redis.watch("zset")

      job = @redis.zrange('zset', '0', '0')

      if job.is_a?(Array) and !job.empty?
        # We only have one entry in our array
        job = job[0]

        res = @redis.multi do
         # Remove from the queue
         @redis.zrem('zset', job );
        end
        job = nil if res.nil?
      end

      @redis.unwatch

      return job if job.is_a?(String)

      sleep(timeout) 
    end
  end

  def run
    Thread.new do
      while( x = fetch() )
        print "\n" if x == "test 1"
        print "#{@name}:#{x}.. "

        $count[x] += 1

        if ( rand(10) > 5 )
          sleep 1
        end

      end

    end
  end

end

$count = Hash.new{|h,k| h[k] = 0}
$threads = []

Signal.trap("INT") do
  pp $count
  exit
end

$threads = [Arse.new("a").run, Arse.new("b").run, Arse.new("c").run]

while $threads.any?{|t| t.alive?} do
  $threads.each do |t|
    next if t.alive?
    t.join
  end
  sleep 1
end
