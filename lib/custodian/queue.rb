#
# Attempt to load the Redis-library.
#
# Without this we cannot connect to our queue.
#
%w( redis ).each do |library|
  begin
    require library
  rescue LoadError
    puts("Failed to load the #{library} library - queue access will fail!")
  end
end



module Custodian


  #
  # An abstraction layer for our queue.
  #
  class QueueType

    #
    # Retrieve a job from the queue.
    #
    def fetch(_timeout)
      raise 'Subclasses must implement this method!'
    end


    #
    # Add a new job to the queue.
    #
    def add(_job_string)
      raise 'Subclasses must implement this method!'
    end


    #
    # Get the size of the queue
    #
    def size?
      raise 'Subclasses must implement this method!'
    end


    #
    # Empty the queue
    #
    def flush!
      raise 'Subclasses must implement this method!'
    end
  end




  #
  # This is a simple queue which uses Redis for storage.
  #
  class RedisQueueType < QueueType


    #
    # Connect to the server on localhost, unless QUEUE_ADDRESS is set.
    #
    def initialize
      host = ENV['QUEUE_ADDRESS'] || '127.0.0.1'
      @redis = Redis.new(:host => host)
    end


    #
    #  Fetch a job from the queue.
    #
    #  The timeout is used to specify the period we wait for a new job, and
    # we pause that same period between fetches.
    #
    def fetch(timeout = 1)
      job = nil

      loop do

        # Get a random job
        job = @redis.spop('custodian_queue')

        # If that worked return it
        if !job.nil?
          return job
        else
          sleep(timeout)
        end
      end
    end


    #
    #  Add a new job to the queue.
    #
    def add(test)

      # Add unless already present
      @redis.sadd('custodian_queue', test) unless
        ( @redis.sismember( 'custodian_queue', test ) )
    end


    #
    #  How many jobs in the queue?
    #
    def size?
      @redis.scard('custodian_queue')
    end


    #
    #  Empty the queue, discarding all pending jobs.
    #
    def flush!
      @redis.del('custodian_queue')
    end

  end

end
