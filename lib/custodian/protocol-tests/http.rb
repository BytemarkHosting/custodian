#!/usr/bin/ruby1.8


require 'custodian/webfetch'


class HTTPTest

  #
  # Data passed from the JSON hash.
  #
  attr_reader :test_data


  #
  # Save the data away.
  #
  def initialize( data )
    @test_data = data
    @error     = nil

    #
    # Ensure we have an URL
    #
    if ( @test_data["target_host"].nil? )
      @error = "Missing URL for the test."
      raise ArgumentError, @error
    end

    #
    # Ensure we have a port
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
    # Run the fetch.
    #
    obj = WebFetch.new( @test_data["target_host"], @test_data["timeout"].to_i )

    #
    # If we succeeded in the fetch
    #
    if ( obj.fetch() )

      #
      #  Do we need to test for a HTTP status code?
      #
      if ( @test_data["http_status"] )

        puts "Testing for HTTP status code: #{@test_data['http_status']}"  if ( @test_data['verbose'] )

        if ( obj.status().to_i != @test_data['http_status'].to_i)
          @error = "#{@error} <p>The HTTP status-code was '#{obj.status}' not '#{@test_data['http_status']}'.</p>"
        end
      end

      #
      #  Do we need to search for text in the body of the reply?
      #
      if ( @test_data['http_text'] )
        puts "Testing for text in the response: '#{@test_data['http_text']}'" if ( @test_data['verbose'] )

        if (! obj.content.match(/#{@test_data['http_text']}/i) )
          @error = "#{@error}<p>The response did not contain our expected text '#{test_data['http_text']}</p>'"
        end
      end

      return true if ( @error.nil? )

      return false
    end

    @error = obj.error()
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
    "target_host" => "http://collector2.sh.bytemark.co.uk/",
    "test_type"   => "http",
    "verbose"     => 1,
    "timeout"     => 3,
    "test_port"   => 80,
    "test_alert"  => "Collector is unavailable",
    "http_status" => "200",
    "http_text"   => "Bytemark Monitor"
  }


  #
  #  Run the test.
  #
  http = HTTPTest.new( test )
  if ( http.run_test )
    puts "TEST OK"
  else
    puts "TEST FAILED"
    puts http.error()
  end

end
