
#
# Our modules.
#
require 'custodian/alerts'
require 'custodian/settings'
require 'custodian/queue'


#
# This list of all our protocol tests.
#
require 'custodian/protocoltests'








#
# This class contains the code for connecting to the queue,
# fetching tests from it, and executing them
#
module Custodian

  class Worker


    #
    # The queue we're using for retrieving tests.
    #
    attr_reader :queue


    #
    # The alerter which is being used.
    #
    # NOTE: There might be more than one, comma-separated.
    #
    attr_reader :alerter


    #
    # How many times we re-test before we detect a failure
    #
    attr_reader :retry_count


    #
    # Should we sleep between repeated tests?
    #
    attr_reader :retry_delay


    #
    # The settings from the global configuration file
    #
    attr_reader :settings




    #
    # Constructor.
    #
    # Connect to the queue, and record interesting settings away.
    #
    def initialize(settings)

      # Save the settings
      @settings = settings

      # Connect to the queue
      @queue = QueueType.create(@settings.queue_type)

      # Get the alerter-type(s) to instantiate
      @alerter = @settings.alerter

      # How many times to repeat a failing test
      @retry_count = @settings.retries

      # Should we sleep between repeated tests?
      @retry_delay = @settings.retry_delay

    end




    #
    # Show a message on STDOUT if "--verbose" was specified.
    #
    def log_message(msg)
      puts msg if  ENV['VERBOSE']
    end




    #
    # Process jobs from the queue - never return.
    #
    def run!
      loop do
        log_message('Waiting for job..')
        process_single_job
      end
    end



    #
    # Fetch a single job from the queue, and dispatch it for
    # processing.
    #
    def process_single_job

      #
      #  Acquire a job from our queue.
      #
      job = @queue.fetch(1)

      #
      #  Ensure that the job is sane.
      #
      raise ArgumentError, 'Job was empty' if job.nil?
      raise ArgumentError, 'Job was not a string' unless job.kind_of?(String)

      #
      # Create test-objects from our class-factory, and process them.
      #
      Custodian::TestFactory.create(job).each do |test|
        process_single_test(test)
      end
    end


    #
    # Process a single test.
    #
    # A test which succeeds will clear any outstanding alert.
    #
    # Any test which fails for N-times in a row will raise an alert.
    #
    def process_single_test(test)

      begin

        log_message("Acquired job: #{test}")

        #
        # The count of times this test has run, the result, and the start-time
        #
        count      = 1
        start_time = Time.now
        run        = true

        #
        #  If a job fails we'll repeat it, but no more than MAX times.
        #
        #  We exit here if we receive a single success.
        #
        while  (count < (@retry_count + 1)) && (run == true)

          log_message("Running test - [#{count}/#{@retry_count}]")

          #
          # Run the test - inverting the result if we should
          #
          result = test.run_test


          #
          #  TODO: This is temporary
          #
          if  (result.is_a?(TrueClass)) ||
               (result.is_a?(FalseClass))
            puts 'ERROR: Class returned boolean'
          end


          #
          #  Invert the test, if the result was pass/fail
          #
          if test.inverted?
            puts "The test was inverted - old result was : #{result}"

            if (result == Custodian::TestResult::TEST_FAILED)
              result = Custodian::TestResult::TEST_PASSED
            else

              # rubocop:disable BlockNesting
              if (result == Custodian::TestResult::TEST_PASSED)
                result = Custodian::TestResult::TEST_FAILED
              end
            end
            puts "The test was inverted - new result is  : #{result}"
          end



          if (result == Custodian::TestResult::TEST_PASSED)
            log_message('Test succeeed - clearing alert')
            do_clear(test)
            run = false
          end

          #
          #  Some of our routers/hosts don't like being hammered.
          #
          #  We delay before re-testing, but we only do this if
          # we're not on the last count.
          #
          #  The intention here is that if the test passes then there will
          # be no delay.  If the test fails then we'll sleep.
          #
          if  (run == true) && (@retry_delay > 0) && (count < @retry_count)
            log_message("Sleeping #{@retry_delay} before retry - failure: #{test.error}")
            sleep(@retry_delay)
          end

          #
          #  Increase the log of times we've repeated the test.
          #
          count += 1
        end

        #
        #  End time
        #
        end_time = Time.now

        #
        #  Duration of the test-run, in milliseconds
        #
        duration = ((end_time - start_time) * 1000.0).to_i


        #
        #  Record that, if we have any alerters that are interested
        # in run-times.
        #
        if  (result == Custodian::TestResult::TEST_FAILED) ||
             (result == Custodian::TestResult::TEST_PASSED)
          do_duration(test, duration)
        end


        #
        #  If we didn't succeed on any of the attempts raise the alert.
        #
        if (result == Custodian::TestResult::TEST_FAILED)

          #
          # Raise the alert, passing the error message.
          #
          log_message("Test failed - alerting with #{test.error}")
          do_raise(test)
        end

      rescue => ex
        log_message("Exception raised processing job: #{ex}")

      end

      result
    end


    #
    # Raise an alert, with each registered alerter.
    #
    def do_raise(test)
      @alerter.split(',').each do |alerter|

        log_message("Creating alerter: #{alerter}")
        alert = Custodian::AlertFactory.create(alerter, test)

        target = @settings.alerter_target(alerter)
        alert.set_target(target)
        log_message("Target for alert is #{target}")

        # give the alerter a reference to the settings object.
        alert.set_settings(@settings)

        alert.raise
      end
    end


    #
    # Clear an alert, with each registered alerter.
    #
    def do_clear(test)
      @alerter.split(',').each do |alerter|
        log_message("Creating alerter: #{alerter}")
        alert  = Custodian::AlertFactory.create(alerter, test)

        target = @settings.alerter_target(alerter)
        alert.set_target(target)
        log_message("Target for alert is #{target}")

        # give the alerter a reference to the settings object.
        alert.set_settings(@settings)

        alert.clear
      end
    end

    #
    #  Log the test duration with each registered alerter.
    #
    def do_duration(test, duration)
      @alerter.split(',').each do |alerter|
        log_message("Creating alerter: #{alerter}")
        alert  = Custodian::AlertFactory.create(alerter, test)

        target = @settings.alerter_target(alerter)
        alert.set_target(target)
        log_message("Target for alert is #{target}")

        # give the alerter a reference to the settings object.
        alert.set_settings(@settings)

        alert.duration(duration) if  alert.respond_to? 'duration'
      end
    end


    #
    #  Process jobs until we see a failure, then stop.
    #
    def process_until_fail
      while process_single_job
        # nop
      end
    end



  end


end
