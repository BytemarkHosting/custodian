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

        # Get the next job from the queue.
        #
        # NOTE: This returns an array - but the array will have only
        # one element because we're picking from element 0 with a range
        # of 0 - which really means 1,1.
        #
        job = @redis.ZREVRANGE('custodian_queue', '0', '0')

        if ! job.empty?

          # We only have one entry in our array
          job = job[0]

          # Remove from the queue
          @redis.zrem('custodian_queue', job );
          return job
        else
          sleep(timeout)
        end

      end
    end


    #
    #  Add a new job to the queue.
    #
    def add(job_string)

      #
      # We need to build a "score" for this job - the score
      # will be used for ordering by Redis.
      #
      # We don't care what order the jobs are running in, however
      # we do care that this the order is always the same.
      #
      # On that basis we need to create a score for the string which
      # will always be the same, and will always be a number.
      #
      # We'll sum up the ASCII values of each character in the test
      # which gives us a "number" which that should be consistent for
      # each distinct-test.
      #
      #
      score = Time.now.to_i
      @redis.zadd('custodian_queue', score, job_string)
    end


    #
    #  How many jobs in the queue?
    #
    def size?
      @redis.zcard('custodian_queue')
    end


    #
    #  Empty the queue, discarding all pending jobs.
    #
    def flush!
      @redis.del('custodian_queue')
    end

  end

end
