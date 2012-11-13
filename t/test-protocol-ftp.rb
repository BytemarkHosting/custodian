#!/usr/bin/ruby -I../worker/tests/ -I./worker/tests/


require 'test/unit'
require 'ftp'




#
# Unit test for the FTP-protocol probe.
#
class TestFTPProtocolProbe < Test::Unit::TestCase

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
  #  Test we can create a new FTPTest object.
  #
  def test_init
    test_data_good = {
      "target_host" => "mirror.bytemark.co.uk",
      "test_type"   => "ftp",
      "verbose"     => 1,
      "test_port"   => 21,
      "test_alert"  => "FTP service down",
    }

    #
    # Missing a port number
    #
    test_data_bad_one = {
      "target_host" => "mirror.bytemark.co.uk",
      "test_type"   => "ftp",
      "verbose"     => 1,
      "test_alert"  => "FTP service down",
    }

    #
    #  Missing URL to probe
    #
    test_data_bad_two = {
      "test_type"   => "ftp",
      "verbose"     => 1,
      "test_port"   => 21,
      "test_alert"  => "FTP service down",
    }


    #
    #  Create a new FTPTest object.  This should succeed
    #
    good = FTPTest.new( test_data_good )
    assert( good )

    #
    #  There will be no error setup
    #
    assert( good.error().nil? )

    #
    #  Now create a probe with a missing port.
    #
    assert_raise ArgumentError do
      bad = FTPTest.new( test_data_bad_one )
    end


    #
    #  Now create a probe with a missing URL.
    #
    assert_raise ArgumentError do
      bad = FTPTest.new( test_data_bad_two )
    end

  end



end
