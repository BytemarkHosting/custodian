#!/usr/bin/ruby -I../lib/ -Ilib/


require 'test/unit'
require 'custodian/protocol-tests/rsync.rb'




#
# Unit test for the RSYNC-protocol probe.
#
class TestRSYNCProtocolProbe < Test::Unit::TestCase

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
  #  Test we can create a new RSYNCTest object.
  #
  def test_init
    test_data_good = {
      "target_host" => "upload.ns.bytemark.co.uk",
      "test_type"   => "rsync",
      "verbose"     => 1,
      "test_port"   => 873,
      "test_alert"  => "DNS upload service is down",
    }

    #
    # Missing a port number
    #
    test_data_bad_one = {
      "target_host" => "upload.ns.bytemark.co.uk",
      "test_type"   => "rsync",
      "verbose"     => 1,
      "test_alert"  => "DNS upload service is down",
    }

    #
    #  Missing host to probe
    #
    test_data_bad_two = {
      "test_type"   => "rsync",
      "verbose"     => 1,
      "test_port"   => 873,
      "test_alert"  => "DNS upload service is down",
    }


    #
    #  Create a new test object.  This should succeed
    #
    good = RSYNCTest.new( test_data_good )
    assert( good )

    #
    #  There will be no error setup
    #
    assert( good.error().nil? )

    #
    #  Now create a probe with a missing port.
    #
    assert_raise ArgumentError do
      bad = RSYNCTest.new( test_data_bad_one )
    end


    #
    #  Now create a probe with a missing host.
    #
    assert_raise ArgumentError do
      bad = RSYNCTest.new( test_data_bad_two )
    end

  end



end
