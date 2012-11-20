#!/usr/bin/ruby1.8



require 'socket'
require 'timeout'


#
# Test that we can receive a ping response from the remote host.
#
class PINGTest

  #
  # Data passed from the JSON hash.
  #
  attr_reader :test_data

  #
  # The error text we return on failure.
  #
  attr_reader :error



  #
  # Save the data away.
  #
  def initialize( data )
    @test_data = data
  end


  #
  # Run the test.
  #
  #  Return "true" on success
  #
  #  Return "false" on failure.
  #
  # If the test fails the details should be retrieved from "error()".
  #
  def run_test

    #
    # Reset state from previous test.
    #
    @error = nil


    #
    # Find the binary we're going to invoke.
    #
    binary = nil
    binary = "/usr/bin/multi-ping"  if ( File.exists?( "/usr/bin/multi-ping" ) )

    if ( binary.nil? )
      @error = "Failed to find 'multi-ping'"
      return false
    end


    #
    #  Get the hostname to test against.
    #
    host = @test_data['target_host']


    #
    # Sanity check the hostname for ping-tests, to
    # avoid this security hole:
    #
    #   $(/tmp/exploit.sh) must run ping ..
    #
    raise ArgumentError, "Invalid hostname for ping-test: #{host}" unless( host =~ /^([a-zA-Z0-9:\-\.]+)$/ )



    #
    # Show the hostname.
    #
    puts "ping testing host #{host}" if ( @test_data['verbose'] )


    if ( system( "#{binary} #{host}" ) == true )
      puts "PING OK" if ( @test_data['verbose'] )
      return true
    else
      @error = "Ping failed.  TODO: Mtr"
      return false
    end

  end


  #
  #  Return the error text for why this test failed.
  #
  def error()
    return @error
  end

end


#
# Sample test, for testing.
#
if __FILE__ == $0 then

  #
  #  Sample data.
  #
  test = {
    "target_host" => "upload.ns.bytemark.co.uk",
    "test_type"   => "ping",
    "verbose"     => 1,
    "timeout"     => 5,
    "test_alert"  => "Pingly faily",
  }


  #
  #  Run the test.
  #
  obj = PINGTest.new( test )
  if ( obj.run_test )
    puts "TEST OK"
  else
    puts "TEST FAILED"
    puts obj.error()
  end

end
