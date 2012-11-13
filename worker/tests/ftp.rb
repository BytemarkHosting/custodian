#!/usr/bin/ruby 


require 'timeout'
require 'socket'

#
# This class is responsible for performing tests against a remote FTP server
#
#
class FTPTest

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
    #  Get the hostname & port to test against.
    #
    host = @test_data["target_host"]
    port = @test_data["test_port"]

    puts "FTP testing host #{host}:#{port}"

    begin
      timeout(3) do

        begin
          socket = TCPSocket.new( host, port )
          socket.puts( "QUIT")

          banner = socket.gets(nil)
          banner = banner[0,20]

          socket.close()

          if ( banner =~ /^220/ )
            return true
          else
            @error = "Banner didn't report OK: #{banner}"
          end
        rescue
          @error = "FTP exception on host #{host}:#{port} - #{$!}"
          return false
        end
      end
    rescue Timeout::Error => e
      @error = "Timed-out connecting #{e}"
      return false
    end
    @error = "Misc. failure."
    return false
  end


  #
  #  Return the error.
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
    "target_host" => "mirror.bytemark.co.uk",
    "test_type"   => "ftp",
    "test_port"   => 21,
    "test_alert"  => "The FTP server no worky",
  }


  #
  #  Run the test.
  #
  tst = FTPTest.new( test )
  if ( tst.run_test )
    puts "TEST OK"
  else
    puts "TEST FAILED"
    puts tst.get_details()
  end

end
