

#
# Standard modules
#
require 'beanstalk-client'
require 'logger'



#
# Our modules.
#
require 'custodian/alerts'
require 'custodian/settings'



#
# This list of all our protocol tests.
#
require 'custodian/protocoltests'








#
# This class contains the code for connecting to a Beanstalk queue,
# fetching tests from it, and executing them
#
module Custodian

  class Worker


    #
    # The beanstalk queue.
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
    # Constructor: Connect to the queue
    #
    def initialize( server, queue, alerter, logfile, settings )

      # Connect to the queue
      @queue = Beanstalk::Pool.new([server], queue )

      # Get the alerter-type to instantiate
      @alerter = alerter

      # Instantiate the logger.
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
    # Fetch a single job from the queue, and process it.
    #
    def process_single_job

      result = false

      begin

        #
        #  Acquire a job.
        #
        job = @queue.reserve()
        log_message( "Job aquired - Job ID : #{job.id}" )

        #
        #  Get the job body
        #
        body = job.body
        raise ArgumentError, "Job was empty" if (body.nil?)
        raise ArgumentError, "Job was not a string" unless body.kind_of?(String)

        #
        #  Output the job.
        #
        log_message( "Job: #{body}" )


        #
        # The count of times this test has run.
        #
        count = 1


        #
        # Create the test-object.
        #
        test = Custodian::TestFactory.create( body )

        start_time = Time.now

        #
        #  We'll run no more than MAX times.
        #
        #  We stop the execution on a single success.
        #
        while ( ( count < @retry_count ) && ( result == false ) )

          log_message( "Running test - [#{count}/#{@retry_count}]" )

          #
          # Run the test - inverting the result if we should
          #
          result = test.run_test
          result = ! result if ( test.inverted() )

          if ( result )
            log_message( "Test succeeed - clearing alert" )
            do_clear( test )
            success = true
          end
          count += 1

          #
          #  Some of our routers don't like being hammered.
          #
          #  We delay before re-testing.
          #
          if ( @retry_delay > 0 )
            puts "Sleeping for #{@retry_delay} seconds to allow cool-down"
            sleep( @retry_delay )
          end
        end

        #
        #  End time
        #
        end_time = Time.now


        #
        #  Duration of the test-run, in milliseconds
        #
        duration = (( end_time - start_time ) * 1000.0).to_i

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
        puts "Exception raised processing job: #{ex}"

      ensure
        #
        #  Delete the job - either we received an error, in which case
        # we should remove it to avoid picking it up again, or we handled
        # it successfully so it should be removed.
        #
        log_message( "Job ID : #{job.id} - Removed" )
        job.delete if ( job )
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
        puts "Target for alert is #{target}"

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
        puts "Target for alert is #{target}"

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
        puts "Target for alert is #{target}"

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
