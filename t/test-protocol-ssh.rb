#!/usr/bin/ruby -I../worker/tests/ -I./worker/tests/


require 'test/unit'
require 'ssh'



#
# Unit test for the SSH-protocol probe.
#
class TestSSHProtocolProbe < Test::Unit::TestCase

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
  #  Test we can create a new SSHTest object.
  #
  def test_init
    test_data_good = {
      "target_host" => "127.0.0.1",
      "test_type"   => "ssh",
      "verbose"     => 1,
      "test_port"   => 22,
      "test_alert"  => "SSH service down",
    }

    #
    # Missing a port number
    #
    test_data_bad_one = {
      "target_host" => "127.0.0.1",
      "test_type"   => "ssh",
      "verbose"     => 1,
      "test_alert"  => "SSH service down",
    }

    #
    #  Missing a host to probe
    #
    test_data_bad_two = {
      "test_type"   => "ssh",
      "verbose"     => 1,
      "test_port"   => 22,
      "test_alert"  => "SSH service down",
    }


    #
    #  Create a new test object.  This should succeed
    #
    good = SSHTest.new( test_data_good )
    assert( good )

    #
    #  There will be no error setup
    #
    assert( good.error().nil? )

    #
    #  Now create a probe with a missing port.
    #
    assert_raise ArgumentError do
      bad = SSHTest.new( test_data_bad_one )
    end


    #
    #  Now create a probe with a missing host.
    #
    assert_raise ArgumentError do
      bad = SSHTest.new( test_data_bad_two )
    end

  end



end
