#!/usr/bin/ruby

require 'net/http'
require 'net/https'
require 'uri'



class HTTPTest

  #
  # Data passed from the JSON hash.
  #
  attr_reader :test_data

  #
  # The HTTP status, the HTTP response body, and the error text
  # we return on failure.
  #
  attr_reader :status, :body, :error



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
    # Ensure we had a URL
    #
    if ( @test_data[:target_host].nil? )
      @error = "Missing URL for the test"
      return false
    end


    #
    #  Do the fetch, if this success then we'll have the
    # @status + @text setup
    #
    if ( getURL (@test_data[:target_host] ) )

      #
      #  Do we need to test for a HTTP status code?
      #
      if ( @test_data[:http_status] )
        puts "Testing for HTTP status code: #{@test_data[:http_status]}"

        if ( @status != @test_data[:http_status].to_i)
          @error = "#{@error} status code was #{@status} not #{@test_data[:http_status]}"
        end
      end

      #
      #  Do we need to search for text in the body of the reply?
      #
      if ( @test_data[:http_text] )
        puts "Testing for text in the response: #{@test_data[:http_text]}"

        if (! @body.match(/#{@test_data[:http_text]}/i) )
          @error = "#{@error} The respond did not contain #{test_data[:http_text]}"
        end
      end

      return true if ( @error.length() == 0 )

      return false
    end

    return false
  end


  #
  #  Return the error text for why this test failed.
  #
  def get_details
    return @error
  end


  #
  # Retrieve a HTTP page from the web.
  #
  # NOTE:  This came from sentinel.
  def getURL (uri_str)
    begin
      uri_str = 'http://' + uri_str unless uri_str.match(/^http/)
      url = URI.parse(uri_str)
      http = Net::HTTP.new(url.host, url.port)
      http.open_timeout = 3
      http.read_timeout = 3

      if (url.scheme == "https")
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end

      response = nil

      if nil == url.query
        response = http.start { http.get(url.path) }
      else
        response = http.start { http.get("#{url.path}?#{url.query}") }
      end

      @status = response.code.to_i
      @body   =  response.body

      return true
    rescue Errno::EHOSTUNREACH => ex
      @error = "no route to host"
      return false
    rescue Timeout::Error => ex
      @error = "time out reached"
      return false
    rescue => ex
      raise ex
      return false
    end
    return false
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
    :target_host => "http://www.steve.org.uk/",
    :test_type   => "http",
    :test_port   => 80,
    :test_alert  => "Steve's website is unavailable",
    :http_text   => "Steve Kemp",
    :http_status => "200"
  }


  #
  #  Run the test.
  #
  http = HTTPTest.new( test )
  if ( http.run_test )
    puts "TEST OK"
  else
    puts "TEST FAILED"
    puts http.get_details()
  end

end
