#
# We don't necessarily expect that both libraries will be present,
# so long as one is that'll allow things to work.
#
%w( redis beanstalk-client ).each do |library|
  begin
    require library
  rescue LoadError
    puts "Failed to load the library: #{library}"
  end
end



module Custodian


  #
  # An abstraction layer for our queue.
  #
  class QueueType

    #
    # Class-Factory
    #
    def self.create type
      case type
      when "redis"
        RedisQueueType.new
      when "beanstalk"
        BeanstalkQueueType.new
      else
        raise "Bad queue-type: #{type}"
      end
    end


    #
    # Retrieve a job from the queue.
    #
    def fetch(timeout)
      raise "Subclasses must implement this method!"
    end


    #
    # Add a new job to the queue.
    #
    def add(job_string)
      raise "Subclasses must implement this method!"
    end


    #
    # Get the size of the queue
    #
    def size?
      raise "Subclasses must implement this method!"
    end

  end




  #
  # This is a simple FIFO queue which uses Redis for storage.
  #
  class RedisQueueType < QueueType


    #
    #  Connect to the server on localhost
    #
    def initialize
      host = ENV["REDIS"] || "127.0.0.1"
      @redis = Redis.new( :host => host )
    end


    #
    #  Fetch a job from the queue - the timeout parameter is ignored.
    #
    def fetch(timeout)
      @redis.lpop( "queue" )
    end

    #
    #  Add a new job to the queue.
    #
    def add(job_string)
      @redis.rpush( "queue", job_string )
    end


    #
    #  How many jobs in the queue?
    #
    def size?
      @redis.llen( "queue" )
    end
  end



  #
  #  Use the beanstalkd-queue for its intended purpose
  #
  class BeanstalkQueueType < QueueType

    #
    #  Connect to the server on localhost
    #
    def initialize
      host = ENV["QUEUE"] || "127.0.0.1:11300"
      @queue = Beanstalk::Pool.new([host] )
    end

    #
    #  Here we fetch a value from the queue, and delete it at the same time.
    #
    #  The timeout is used to specify the period we wait for a new job.
    #
    def fetch(timeout)
      begin
        j = @queue.reserve(timeout)
        if ( j ) then
          b = j.body
          j.delete
          return b
        else
          raise "ERRROR"
        end
      rescue Beanstalk::TimedOut => ex
        return nil
      end
    end


    #
    #  Add a new job to the queue.
    #
    def add(job_string)
      @queue.put(job_string)
    end


    #
    #  Get the size of the queue
    #
    def size?
      stats = @queue.stats()
      ( stats['current-jobs-ready'] || 0 )
    end

  end

end
