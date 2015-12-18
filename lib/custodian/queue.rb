#
# We don't necessarily expect that both libraries will be present,
# so long as one is that'll allow things to work.
#
%w( redis beanstalk-client ).each do |library|
  begin
    require library
  rescue LoadError
    ENV['DEBUG'] && puts("Failed to load the library: #{library}")
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
    def self.create(type)
      case type
      when 'redis'
        RedisQueueType.new
      when 'beanstalk'
        BeanstalkQueueType.new
      else
        raise "Bad queue-type: #{type}"
      end
    end


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
        # NOTE: This returns an array.
        job = @redis.zrange('custodian_queue', 0, 0)

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
      score = 0
      job_string.split("").each do |x|
        score = score + x.ord
      end

      # Bound the number to something sane.
      score = score & 0xFFFF

      puts job_string, score
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



  #
  #  Use the beanstalkd-queue for its intended purpose
  #
  class BeanstalkQueueType < QueueType

    #
    # Connect to the server on localhost, unless QUEUE_ADDRESS is set.
    #
    def initialize
      host  = ENV['QUEUE_ADDRESS'] || '127.0.0.1'
      @queue = Beanstalk::Pool.new(["#{host}:11300"])
    end


    #
    #  Here we fetch a value from the queue, and delete it at the same time.
    #
    #  The timeout is used to specify the period we wait for a new job.
    #
    def fetch(timeout)
      begin
        j = @queue.reserve(timeout)
        if  j  then
          b = j.body
          j.delete
          return b
        else
          raise 'ERRROR'
        end
      rescue Beanstalk::TimedOut => _ex
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
      stats = @queue.stats
      (stats['current-jobs-ready'] || 0)
    end


    #
    # Flush the queue, discarding all pending jobs.
    #
    def flush!
      while fetch(1)
        # nop
      end
    end
  end

end
