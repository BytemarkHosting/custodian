#!/usr/bin/ruby1.8 -I./lib/ -I../lib/


require 'custodian/util/dns'
require 'test/unit'



#
# Unit test for our DNS utility class.
#
#
class TestDNSUtil < Test::Unit::TestCase

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
  #  Test forward lookups
  #
  def test_lookup

    #
    # IPv6 lookup
    #
    details = Custodian::Util::DNS.hostname_to_ip( "ipv6.steve.org.uk" )
    assert( details =~ /2001:41c8:51:2aa:feff:ff:fe00:ec3/i )

    #
    # IPv4 lookup
    #
    details = Custodian::Util::DNS.hostname_to_ip( "ipv4.steve.org.uk" )
    assert( details =~ /213\.138\.103\.170/i )

    #
    # Failure case
    #
    details = Custodian::Util::DNS.hostname_to_ip( "this.doesnot.exist" )
    assert( details.nil? )

  end


  #
  #  Test forward lookups
  #
  def test_reverse_lookup

    #
    # IPv6 lookup
    #
    details = Custodian::Util::DNS.ip_to_hostname( "2001:41c8:125:46::22" )
    assert( details =~ /ssh.steve.org.uk/i )

    #
    # IPv4 lookup
    #
    details = Custodian::Util::DNS.ip_to_hostname( "80.68.85.48" )
    assert( details =~ /ssh.steve.org.uk/i )

    #
    # Bogus lookup - should return nil.
    #
    details = Custodian::Util::DNS.ip_to_hostname( "800.683.853.348" )
    assert( details.nil? )
  end

end
