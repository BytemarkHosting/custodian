#!/usr/bin/ruby1.8 -I./lib/ -I../lib/



require 'test/unit'
require 'custodian/multiping'



#
# Unit test for our multi-ping tool.
#
class TestMultiPing < Test::Unit::TestCase

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
  # Ensure we can instantiate the object
  #
  def test_init


    #
    #  Calling without a hostname is a mistake.
    #
    assert_raise ArgumentError do
      obj = MultiPing.new()
    end

    #
    #  Calling with a hostname should be fine mistake.
    #
    assert_nothing_raised do
      obj = MultiPing.new( "some.host.anme" )
    end
  end


  #
  #  Test address-family detection
  #
  def test_families

    #
    #  Hash of hostnames and version of address.
    #
    to_test = {
      "ipv6.steve.org.uk" => 6,
      "ipv6.google.com"   => 6,

      "ipv4.steve.org.uk" => 4,
      "google.com"        => 4,
    }


    to_test.each do |name,version|

      a = MultiPing.new( name )

      if ( version == 6 )
        assert_equal( a.is_ipv6?, true, "#{name} is IPv6" )
        assert_equal( a.is_ipv4?, false, "#{name} is not IPv4" )
      end

      if ( version == 4 )
        assert_equal( a.is_ipv6?, false, "#{name} is not IPv6" )
        assert_equal( a.is_ipv4?, true, "#{name} is IPv4" )
      end
    end
  end



  #
  #  Test that bogus hosts are not reported as either IPv4 or IPv6
  #
  def test_bogus

    %w( tessf.dfsdf.sdf.sdfsdf fdsfkljflj3.fdsfds.f3.dfs ).each do |name|
      helper = MultiPing.new( name )

      assert( ! helper.is_ipv4? )
      assert( ! helper.is_ipv6? )
    end
  end


end
