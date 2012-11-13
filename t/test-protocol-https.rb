#!/usr/bin/ruby -I../worker/tests/ -I./worker/tests/


require 'test/unit'
require 'https'




#
# Unit test for the HTTPS-protocol probe.
#
class TestHTTPSProtocolProbe < Test::Unit::TestCase

  #
  # Create the test suite environment: NOP.
  #
  def setup
  end

  #
  # Destroy the test suite environment: NOP.
  #
  def teardown
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
    good = HTTPSTest.new( test_data_good )
    assert( good )

    #
    #  There will be no error setup
    #
    assert( good.error().nil? )

    #
    #  Now create a probe with a missing port.
    #
    assert_raise ArgumentError do
      bad = HTTPSTest.new( test_data_bad_one )
    end


    #
    #  Now create a probe with a missing URL.
    #
    assert_raise ArgumentError do
      bad = HTTPSTest.new( test_data_bad_two )
    end

  end



end
