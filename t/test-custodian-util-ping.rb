#!/usr/bin/ruby1.8 -I./lib/ -I../lib/


require 'custodian/util/ping'
require 'test/unit'



#
# Unit test for our ping utility class.
#
#
class TestPingUtil < Test::Unit::TestCase

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
  # Test we can construct new objects.
  #
  def test_init

    #
    # Normal construction works.
    #
    assert_nothing_raised do
        Custodian::Util::Ping.new("foo")
    end

    #
    # A hostname must be supplied
    #
    assert_raise ArgumentError do
        Custodian::Util::Ping.new( nil )
    end


    #
    # A hostname is a string, not an array, hash, or similar.
    #
    assert_raise ArgumentError do
      Custodian::Util::Ping.new( Hash.new)
    end
    assert_raise ArgumentError do
      Custodian::Util::Ping.new( Array.new)
    end


  end


  #
  #  Test IPv4 lookups
  #
  def test_lookup_ipv4

    helper = Custodian::Util::Ping.new( "ipv4.steve.org.uk" );
    assert( helper.is_ipv4? )
    assert( ! helper.is_ipv6? )

  end


  #
  #  Test IPv6 lookups
  #
  def test_lookup_ipv6

    helper = Custodian::Util::Ping.new( "ipv6.steve.org.uk" );
    assert( helper.is_ipv6? )
    assert( ! helper.is_ipv4? )
  end


  #
  #  Test lookup of hosts that don't work
  #
  def test_lookup_fail
    %w( tessf.dfsdf.sdf.sdfsdf fdsfkljflj3.fdsfds.f3.dfs ).each do |name|
      assert_nothing_raised do
        helper = Custodian::Util::Ping.new( name )

        assert( ! helper.is_ipv4? )
        assert( ! helper.is_ipv6? )
      end
    end

  end


end
