#!/usr/bin/ruby -I../lib/ -Ilib/


require 'test/unit'
require 'custodian/protocol-tests/ldap.rb'




#
# Unit test for the LDAP-protocol probe.
#
class TestLDAPProtocolProbe < Test::Unit::TestCase

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
  #  Test we can create a new LDAPTest object.
  #
  def test_init
    test_data_good = {
      "target_host" => "auth.bytemark.co.uk",
      "test_type"   => "ldap",
      "verbose"     => 1,
      "test_port"   => 389,
      "test_alert"  => "LDAP server gone away?",
    }

    #
    # Missing a port number
    #
    test_data_bad_one = {
      "target_host" => "auth.bytemark.co.uk",
      "test_type"   => "ldap",
      "verbose"     => 1,
      "test_alert"  => "LDAP server gone away?",
    }

    #
    #  Missing URL to probe
    #
    test_data_bad_two = {
      "test_type"   => "ldap",
      "verbose"     => 1,
      "test_port"   => 389,
      "test_alert"  => "LDAP server gone away?",
    }


    #
    #  Create a new test object.  This should succeed
    #
    good = LDAPTest.new( test_data_good )
    assert( good )

    #
    #  There will be no error setup
    #
    assert( good.error().nil? )

    #
    #  Now create a probe with a missing port.
    #
    assert_raise ArgumentError do
      bad = LDAPTest.new( test_data_bad_one )
    end


    #
    #  Now create a probe with a missing host.
    #
    assert_raise ArgumentError do
      bad = LDAPTest.new( test_data_bad_two )
    end

  end



end
