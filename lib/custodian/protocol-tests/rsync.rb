#!/usr/bin/ruby1.8



require 'socket'
require 'timeout'


#
# Test that we can receive a response from an rsync server that looks
# reasonable.
#
class RSYNCTest

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
    @error     = nil

    #
    # Ensure we have a host to probe
    #
    if ( @test_data["target_host"].nil? )
      @error = "Missing target for the test."
      raise ArgumentError, @error
    end

    #
    # Ensure we have a port to test.
    #
    if ( @test_data["test_port"].nil? )
      @error = "Missing port for the test."
      raise ArgumentError, @error
    end
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
    #  Get the hostname & port to test against.
    #
    host = @test_data['target_host']
    port = @test_data['test_port']

    puts "rsync testing host #{host}:#{port}" if ( @test_data['verbose'] )

    begin
      timeout(3) do

        begin
          socket = TCPSocket.new( host, port )
          socket.puts( "QUIT")

          banner = socket.gets(nil)
          banner = banner[0,20]

          socket.close()

          if ( banner =~ /rsyncd/i )
            puts "rsync alive: #{banner}" if ( @test_data['verbose'] )
            return true
          else
            @error = "Banner didn't seem reasonable: #{banner}"
            return false;
          end
        rescue
          @error = "rsync exception on host #{host}:#{port} - #{$!}"
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
  def error
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
    "test_type"   => "rsync",
    "verbose"     => 1,
    "test_alert"  => "DNS upload service failure",
  }


  #
  #  Run the test.
  #
  obj = RSYNCTest.new( test )
  if ( obj.run_test )
    puts "TEST OK"
  else
    puts "TEST FAILED"
    puts obj.error()
  end

end

