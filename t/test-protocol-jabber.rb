#!/usr/bin/ruby -I../worker/tests/ -I./worker/tests/


require 'test/unit'
require 'jabber'




#
# Unit test for the Jabber-protocol probe.
#
class TestJABBERProtocolProbe < Test::Unit::TestCase

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
  #  Test we can create a new JABBERTest object.
  #
  def test_init
    test_data_good = {
      "target_host" => "chat.bytemark.co.uk",
      "test_type"   => "jabber",
      "test_port"   => 5222,
      "verbose"     => 1,
      "test_alert"  => "Chat server is down",
    }

    #
    # Missing a port number
    #
    test_data_bad_one = {
      "target_host" => "chat.bytemark.co.uk",
      "test_type"   => "jabber",
      "verbose"     => 1,
      "test_alert"  => "Chat server is down",
    }

    #
    #  Missing a host to probe
    #
    test_data_bad_two = {
      "test_type"   => "jabber",
      "test_port"   => 5222,
      "verbose"     => 1,
      "test_alert"  => "Chat server is down",
    }


    #
    #  Create a new test object.  This should succeed
    #
    good = JABBERTest.new( test_data_good )
    assert( good )

    #
    #  There will be no error setup
    #
    assert( good.error().nil? )

    #
    #  Now create a probe with a missing port.
    #
    assert_raise ArgumentError do
      bad = JABBERTest.new( test_data_bad_one )
    end


    #
    #  Now create a probe with a missing host.
    #
    assert_raise ArgumentError do
      bad = JABBERTest.new( test_data_bad_two )
    end

  end



end
