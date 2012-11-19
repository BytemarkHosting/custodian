

#
# Standard modules
#
require 'beanstalk-client'
require 'json'
require 'logger'



#
# Implementation of our protocol tests.
#
require 'custodian/alerter.rb'
require 'custodian/protocol-tests/dns.rb'
require 'custodian/protocol-tests/ftp.rb'
require 'custodian/protocol-tests/http.rb'
require 'custodian/protocol-tests/jabber.rb'
require 'custodian/protocol-tests/ldap.rb'
require 'custodian/protocol-tests/ping.rb'
require 'custodian/protocol-tests/rsync.rb'
require 'custodian/protocol-tests/smtp.rb'
require 'custodian/protocol-tests/ssh.rb'
require 'custodian/protocol-tests/tcp.rb'









#
# This class contains the code for connecting to a Beanstalk queue,
# fetching tests from it, and executing them
#
class Custodian

  #
  # The beanstalk queue.
  #
  attr_reader :queue

  #
  # How many times we re-test before we detect a failure
  #
  attr_reader :retry_count

  #
  # The log-file object
  #
  attr_reader :logger

  #
  # Constructor: Connect to the queue
  #
  def initialize( server, logfile )

    # Connect to the queue
    @queue = Beanstalk::Pool.new([server])

    # Instantiate the logger.
    @logger = Logger.new( logfile, "daily" )

    if ( ENV['REPEAT'] )
       @retry_count=ENV['REPEAT'].to_i
    else
       @retry_count=3
    end

  end



  #
  # Write the given message to our logfile - and show it to the console
  # if we're running with '--verbose' in play
  #
  def log_message( msg )
      @logger.info( msg )
      puts msg if ( ENV['VERBOSE'] )
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
      job = @queue.reserve()

      log_message( "Job aquired - Job ID : #{job.id}" )


      #
      #  Get the job body
      #
      json = job.body
      raise ArgumentError, "Body doesn't look like JSON" unless( json =~ /[{}]/ )


      #
      # Decode the JSON body - it should return a non-empty hash.
      #
      hash = JSON.parse( json )

      #
      # Ensure we got a non-empty hash.
      #
      raise ArgumentError, "JSON didn't decode to a hash" unless hash.kind_of?(Hash)
      raise ArgumentError, "JSON hash is empty" if (hash.empty?)

      #
      # Are we being verbose?
      #
      hash['verbose'] = 1 if ( ENV['VERBOSE'] )


      #
      #  Output the details.
      #
      log_message( "Job body contains the following keys & values:")
      hash.keys.each do |key|
        log_message( "   #{key} => #{hash[key]}" )
      end



      #
      # Did the test succeed?  If not count the number of times it failed in
      # a row.  We'll repeat several times
      #
      success = false
      count   = 0

      #
      # As a result of this test we'll either raise/clear with mauve.
      #
      # This helper will do that job.
      #
      alert = Alerter.new( hash )


      #
      # Convert the test-type to a class name, to do the protocol test.
      #
      # Given a test-type "foo" we'll attempt to instantiate a class called FOOTest.
      #
      test  = hash['test_type']
      test  = "http" if ( test == "https" )
      clazz = test.upcase
      clazz = "#{clazz}Test"


      #
      # Create the test object.
      #
      obj = eval(clazz).new( hash )


      #
      # Ensure that the object we load implements the two methods
      # we expect.
      #
      if ( ( ! obj.respond_to?( "error") ) ||
           ( ! obj.respond_to?( "run_test" ) ) )
        puts "Class #{clazz} doesn't implement the full protocol-test API"
      end



      #
      #  We'll run no more than MAX times.
      #
      #  We stop the execution on a single success.
      #
      while ( ( count < @retry_count ) && ( success == false ) )

        log_message( "Running test - [#{count}/#{@retry_count}]" )

        if ( obj.run_test() )
          log_message( "Test succeeed - clearing alert" )
          success = true
          alert.clear()
          result = true
        end
        count += 1
      end

      #
      #  If we didn't succeed on any of the attempts raise the alert.
      #
      if ( ! success )

        #
        # Raise the alert, passing the error message.
        #
        log_message( "Test failed - alerting with #{obj.error()}" )
        alert.raise( obj.error() )
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
  #  Process jobs until we see a failure - stop then.
  #
  def process_until_fail
      while( process_single_job() )
          # nop
      end
  end

end



