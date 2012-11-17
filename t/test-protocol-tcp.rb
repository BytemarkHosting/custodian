#!/usr/bin/ruby -I../lib/ -Ilib/


require 'test/unit'
require 'custodian/protocol-tests/tcp.rb'




#
# Unit test for the TCP-protocol probe.
#
class TestTCPProtocolProbe < Test::Unit::TestCase

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
  #  Test we can create a new TCPTest object.
  #
  def test_init
    test_data_good = {
      "target_host" => "smtp.bytemark.co.uk",
      "test_type"   => "tcp",
      "banner"      => 220,
      "verbose"     => 1,
      "test_port"   => 25,
      "test_alert"  => "SMTP service down",
    }

    #
    # Missing a port number
    #
    test_data_bad_one = {
      "target_host" => "smtp.bytemark.co.uk",
      "test_type"   => "tcp",
      "banner"      => 220,
      "verbose"     => 1,
      "test_alert"  => "SMTP service down",
    }

    #
    #  Missing a target host to probe
    #
    test_data_bad_two = {
      "test_type"   => "tcp",
      "banner"      => 220,
      "verbose"     => 1,
      "test_port"   => 25,
      "test_alert"  => "SMTP service down",
    }


    #
    #  Create a new FTPTest object.  This should succeed
    #
    good = TCPTest.new( test_data_good )
    assert( good )

    #
    #  There will be no error setup
    #
    assert( good.error().nil? )

    #
    #  Now create a probe with a missing port.
    #
    assert_raise ArgumentError do
      bad = TCPTest.new( test_data_bad_one )
    end


    #
    #  Now create a probe with a missing host.
    #
    assert_raise ArgumentError do
      bad = TCPTest.new( test_data_bad_two )
    end

  end



end
