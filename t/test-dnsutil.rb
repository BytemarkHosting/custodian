#!/usr/bin/ruby1.8 -I./lib/ -I../lib/


require 'custodian/dnsutil'
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
    details = DNSUtil.hostname_to_ip( "ipv6.steve.org.uk" )
    assert( details =~ /2001:41c8:125:46::10/i )

    #
    # IPv4 lookup
    #
    details = DNSUtil.hostname_to_ip( "ipv4.steve.org.uk" )
    assert( details =~ /80.68.85.46/i )

    #
    # Failure case
    #
    details = DNSUtil.hostname_to_ip( "this.doesnot.exist" )
    assert( details.nil? )

  end


  #
  #  Test forward lookups
  #
  def test_reverse_lookup

    #
    # IPv6 lookup
    #
    details = DNSUtil.ip_to_hostname( "2001:41c8:125:46::22" )
    assert( details =~ /ssh.steve.org.uk/i )

    #
    # IPv4 lookup
    #
    details = DNSUtil.ip_to_hostname( "80.68.85.48" )
    assert( details =~ /ssh.steve.org.uk/i )

    #
    # Bogus lookup - should return nil.
    #
    details = DNSUtil.ip_to_hostname( "800.683.853.348" )
    assert( details.nil? )
  end

end
