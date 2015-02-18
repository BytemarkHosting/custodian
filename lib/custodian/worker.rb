

#
# Standard modules
#
require 'logger'



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
    # The name of the alerter to use.
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
    # The log-file object
    #
    attr_reader :logger


    #
    # The settings from the global configuration file
    #
    attr_reader :settings




    #
    # Constructor: Connect to the queue, and setup our settings.
    #
    def initialize( settings )

      # Connect to the queue
      @queue = QueueType.create( settings.queue_type() )

      # Get the alerter-type to instantiate
      @alerter = settings.alerter

      # Instantiate the logger.
      logfile = settings.log_file
      @logger = Logger.new( logfile, "daily" )

      # Save the settings
      @settings = settings

      # How many times to repeat a failing test
      @retry_count=@settings.retries()

      # Should we sleep between repeated tests?
      @retry_delay = @settings.retry_delay()

    end




    #
    # Write the given message to our logfile - and show it to the console
    # if we're running with '--verbose' in play
    #
    def log_message( msg )
      @logger.info( msg )
      puts msg
    end




    #
    # Process jobs from the queue - never return.
    #
    def run!
      while( true )
        log_message( "\n" )
        log_message( "\n" )
        log_message( "Waiting for job.." )
        process_single_job()
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
      raise ArgumentError, "Job was empty" if (job.nil?)
      raise ArgumentError, "Job was not a string" unless job.kind_of?(String)


      #
      # Create the test-object from our class-factory
      #
      Custodian::TestFactory.create( job ).each do |test|
        process_single_test( test )
      end
    end


    #
    # Fetch a single job from the queue, and process it.
    #
    def process_single_test( test )

      begin

        log_message( "Received job: #{test.to_s}" )

        #
        # The count of times this test has run, the result, and the start-time
        #
        count      = 1
        result     = false
        start_time = Time.now

        #
        #  If a job fails we'll repeat it, but no more than MAX times.
        #
        #  We exit here if we receive a single success.
        #
        while ( ( count < ( @retry_count + 1 ) ) && ( result == false ) )

          log_message( "Running test - [#{count}/#{@retry_count}]" )

          #
          # Run the test - inverting the result if we should
          #
          result = test.run_test
          result = ! result if ( test.inverted() )

          if ( result )
            log_message( "Test succeeed - clearing alert" )
            do_clear( test )
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
          if ( ( result == false ) && ( @retry_delay > 0 ) && ( count < @retry_count ) )
            log_message( "Sleeping for #{@retry_delay} seconds to allow cool-down" )
            sleep( @retry_delay )
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
        duration = (( end_time - start_time ) * 1000.0).to_i


        #
        #  Record that, if we have any alerters that are interested
        # in run-times.
        #
        do_duration( test, duration )


        #
        #  If we didn't succeed on any of the attempts raise the alert.
        #
        if ( ! result )

          #
          # Raise the alert, passing the error message.
          #
          log_message( "Test failed - alerting with #{test.error()}" )
          do_raise( test )
        end

      rescue => ex
        log_message( "Exception raised processing job: #{ex}" )

      end

      return result
    end


    #
    # Raise an alert, with each registered alerter.
    #
    def do_raise( test )
      @alerter.split( "," ).each do |alerter|

        log_message( "Creating alerter: #{alerter}" )
        alert = Custodian::AlertFactory.create( alerter, test )

        target = @settings.alerter_target( alerter )
        alert.set_target( target )
        log_message("Target for alert is #{target}")

        # give the alerter a reference to the settings object.
        alert.set_settings( @settings )

        alert.raise()
      end
    end


    #
    # Clear an alert, with each registered alerter.
    #
    def do_clear( test )
      @alerter.split( "," ).each do |alerter|
        log_message( "Creating alerter: #{alerter}" )
        alert  = Custodian::AlertFactory.create( alerter, test )

        target = @settings.alerter_target( alerter )
        alert.set_target( target )
        log_message( "Target for alert is #{target}" )

        # give the alerter a reference to the settings object.
        alert.set_settings( @settings )

        alert.clear()
      end
    end

    #
    #  Log the test duration with each registered alerter.
    #
    def do_duration( test, duration )
      @alerter.split( "," ).each do |alerter|
        log_message( "Creating alerter: #{alerter}" )
        alert  = Custodian::AlertFactory.create( alerter, test )

        target = @settings.alerter_target( alerter )
        alert.set_target( target )
        log_message( "Target for alert is #{target}" )

        # give the alerter a reference to the settings object.
        alert.set_settings( @settings )

        alert.duration( duration ) if ( alert.respond_to? "duration" )
      end
    end


    #
    #  Process jobs until we see a failure, then stop.
    #
    def process_until_fail
      while( process_single_job() )
        # nop
      end
    end



  end


end
