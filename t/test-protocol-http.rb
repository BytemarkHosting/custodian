#!/usr/bin/ruby -I../worker/tests/ -I./worker/tests/


require 'test/unit'
require 'webrick'
require 'http'




#
# Unit test for the HTTP-protocol probe.
#
class TestHTTPProtocolProbe < Test::Unit::TestCase


  #
  # Holder for the new thread we launch, and the servr
  # we run within it.
  #
  attr_reader :server, :server_thread


  #
  # Create the test suite environment: Launch a HTTP server in a new thread.
  #
  def setup
    @server_thread = Thread.new do
      @server = WEBrick::HTTPServer.new( :Port => 12000,
                                         :DocumentRoot => "/tmp",
                                         :AccessLog => [])
      @server.start
    end
  end


  #
  # Destroy the test suite environment: Kill the HTTP-Server
  #
  def teardown
    @server_thread.kill!
  end


  #
  #  Test we can create a new HTTPTest object.
  #
  def test_init
    test_data_good = {
      "target_host" => "http://www.steve.org.uk/",
      "test_type"   => "http",
      "verbose"     => 1,
      "test_port"   => 80,
      "test_alert"  => "Steve's website is unavailable",
      "http_text"   => "Steve Kemp",
      "http_status" => "200"
    }

    #
    # Missing a port number
    #
    test_data_bad_one = {
      "target_host" => "http://www.steve.org.uk/",
      "test_type"   => "http",
      "verbose"     => 1,
      "test_alert"  => "Steve's website is unavailable",
      "http_text"   => "Steve Kemp",
      "http_status" => "200"
    }

    #
    #  Missing URL to probe
    #
    test_data_bad_two = {
      "test_type"   => "http",
      "test_port"   => 80,
      "verbose"     => 1,
      "test_alert"  => "Steve's website is unavailable",
      "http_text"   => "Steve Kemp",
      "http_status" => "200"
    }


    #
    #  Create a new HTTPTest object.  This should succeed
    #
    good = HTTPTest.new( test_data_good )
    assert( good )

    #
    #  There will be no error setup
    #
    assert( good.error().nil? )

    #
    #  Now create a probe with a missing port.
    #
    assert_raise ArgumentError do
      bad = HTTPTest.new( test_data_bad_one )
    end


    #
    #  Now create a probe with a missing URL.
    #
    assert_raise ArgumentError do
      bad = HTTPTest.new( test_data_bad_two )
    end

  end



  #
  #  Test we can make a HTTP fetch, and retrieve the status code
  # against our stub-Webbrick server.
  #
  def test_http_fetch

    test_probe = {
      "target_host" => "http://localhost:12000/",
      "test_type"   => "http",
      "verbose"     => 1,
      "test_port"   => 12000,
      "http_status" => "200"
    }

    #
    #  Create a new HTTPTest object.  This should succeed
    #
    test = HTTPTest.new( test_probe )
    assert( test )


    #
    #  Make the test - ensure that:
    #
    # a. There is no error before it is tested.
    #
    # b. The test method "run_test" returns true.
    #
    # c. There is no error logged after completion.
    #
    assert( test.error().nil? )
    assert( test.run_test() )
    assert( test.error().nil? )
  end

end
