#!/usr/bin/ruby -I../worker/tests/ -I./worker/tests/


require 'test/unit'
require 'smtp'




#
# Unit test for the SMTP-protocol probe.
#
class TestSMTPProtocolProbe < Test::Unit::TestCase

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
  #  Test we can create a new SMTPTest object.
  #
  def test_init
    test_data_good = {
      "target_host" => "statler.bytemark.co.uk",
      "test_type"   => "smtp",
      "test_port"   => 25,
      "verbose"     => 1,
      "test_alert"  => "SMTP service down",
    }

    #
    # Missing a port number
    #
    test_data_bad_one = {
      "target_host" => "statler.bytemark.co.uk",
      "test_type"   => "smtp",
      "verbose"     => 1,
      "test_alert"  => "SMTP service down",
    }

    #
    #  Missing host to probe
    #
    test_data_bad_two = {
      "test_type"   => "smtp",
      "verbose"     => 1,
      "test_port"   => 25,
      "test_alert"  => "SMTP service down",
    }


    #
    #  Create a new SMTPTest object.  This should succeed
    #
    good = SMTPTest.new( test_data_good )
    assert( good )

    #
    #  There will be no error setup
    #
    assert( good.error().nil? )

    #
    #  Now create a probe with a missing port.
    #
    assert_raise ArgumentError do
      bad = SMTPTest.new( test_data_bad_one )
    end


    #
    #  Now create a probe with a missing host.
    #
    assert_raise ArgumentError do
      bad = SMTPTest.new( test_data_bad_two )
    end

  end



end
