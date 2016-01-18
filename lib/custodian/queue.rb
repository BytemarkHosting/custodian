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
        job = @redis.zrange('zset', '0', '0')

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


    #
    #  Add a new job to the queue - this can stall for the case where the
    # job is already pending.
    #
    def add(test)

        @redis.watch('zset')

        #
        # Count the number of times we attempt to add the test
        #
        attempts = 0
        added    = false


        #
        # This is run in a loop, as we have to wait until both
        #
        # (a) the score is missing
        # (b) the zadd function succeeds
        #
        while( attempts < 40 ) do

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
              added = true
            end.nil?
          end

          #
          # This could be tighter..
          #
          sleep 0.1

          #
          # Bump the count of attempts.
          #
          attempts = attempts + 1
        end

        #
        # Do we need to unwatch here?
        #
        @redis.unwatch

        #
        # Return the success/fail
        #
        return added
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
