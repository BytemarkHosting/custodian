#!/usr/bin/ruby



require 'socket'
require 'timeout'


#
# Test that we can receive a response from an LDAP server.
#
class LDAPTest

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
  # If the test fails the details should be retrieved from "get_details".
  #
  def run_test

    #
    # Until the test runs we have no error.
    #
    @error = ""

    #
    #  Get the hostname & port to test against.
    #
    host = @test_data['target_host']
    port = @test_data['test_port']

    puts "LDAP testing host #{host}:#{port}" if ( @test_data['verbose'] )

    begin
      timeout(3) do

        begin
          socket = TCPSocket.new( host, port )
          socket.puts( "QUIT")
          socket.close()

          puts "LDAP alive" if ( @test_data['verbose'] )
          return true
        rescue
          @error = "Exception connecting to host #{host}:#{port} - #{$!}"
          return false
        end
      end
    rescue Timeout::Error => e
      @error = "TIMEOUT: #{e}"
      return false
    end

    @error = "Misc failure"
    return false
  end



  #
  #  Return the error text for why this test failed.
  #
  def get_details
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
    "target_host" => "auth.bytemark.co.uk",
    "test_type"   => "ldap",
    "test_port"   => 389,
    "verbose"     => 1,
    "test_alert"  => "LDAP is down?",
  }


  #
  #  Run the test.
  #
  obj = LDAPTest.new( test )
  if ( obj.run_test )
    puts "TEST OK"
  else
    puts "TEST FAILED"
    puts obj.get_details()
  end

end
