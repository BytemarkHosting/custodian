#!/usr/bin/ruby



require 'socket'
require 'timeout'


#
# Test that we can receive a response from a Jabber server that looks
# reasonable.
#
class JABBERTest

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
    @error = ""

    #
    #  Get the hostname & port to test against.
    #
    host = @test_data['target_host']
    port = 5222

    puts "Jabber testing host #{host}:#{port}" if ( @test_data['verbose'] )

    begin
      timeout(3) do

        begin
          socket = TCPSocket.new( host, port )
          socket.puts( "QUIT")

          banner = socket.gets(nil)
          banner = banner[0,20]

          socket.close()

          if ( banner =~ /xml version/i )
            puts "Jabber alive: #{banner}" if ( @test_data['verbose'] )
            return true
          else
            @error = "Banner didn't seem reasonable: #{banner}"
            return false;
          end
        rescue
          @error = "Jabber exception on host #{host}:#{port} - #{$!}"
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
    "target_host" => "chat.bytemark.co.uk",
    "test_type"   => "jabber",
    "verbose"     => 1,
    "test_alert"  => "Chat is down?",
  }


  #
  #  Run the test.
  #
  obj = JABBERTest.new( test )
  if ( obj.run_test )
    puts "TEST OK"
  else
    puts "TEST FAILED"
    puts obj.get_details()
  end

end
