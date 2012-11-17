#!/usr/bin/ruby1.8



require 'socket'
require 'timeout'


#
# Test that we can receive a response from a TCP server that matches
# a given banner.
#
class TCPTest

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
  # If the test fails the details should be retrieved from "error".
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

    #
    #  Get the banner we expect
    #
    banner = @test_data['banner']

    puts "TCP testing host #{host}:#{port}" if ( @test_data['verbose'] )
    if ( @test_data['verbose'] && ( !banner.nil? ) )
        puts "Looking for banner '#{banner}'"
    end

    begin
      timeout(@test_data["timeout"].to_i) do

        begin
          socket = TCPSocket.new( host, port )
          socket.puts( "QUIT")

          # read a banner from the remote server
          read = socket.gets(nil)

          # trim to a sane length & strip newlines.
          read = read[0,255]
          read.gsub!(/[\n\r]/, "") unless ( read.nil? )

          socket.close()


          if ( banner.nil? )
            return true
          else
            # test for banner
            if ( read =~ /#{banner}/i )
              puts "We connected and matched the banner against '#{read}'" if ( @test_data['verbose'] )
              return true
            end

            @error = "We expected a banner matching '#{banner}' but we got '#{read}'"
            return false
          end
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
  def error
    return @error
  end

end


#
# Sample test, for basic testing.
#
if __FILE__ == $0 then

  #
  #  Sample data.
  #
  test = {
    "target_host" => "mail.steve.org.uk",
    "test_type"   => "tcp",
    "test_port"   => "25",
    "banner"      => "SMTP",
    "verbose"     => 1,
    "timeout"     => 5,
    "test_alert"  => "TCP-port failure",
  }


  #
  #  Run the test.
  #
  obj = TCPTest.new( test )
  if ( obj.run_test )
    puts "TEST OK"
  else
    puts "TEST FAILED"
    puts obj.error()
  end

end
