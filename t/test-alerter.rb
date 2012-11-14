#!/usr/bin/ruby1.8 -I./lib/ -I../lib/



require 'test/unit'
require 'custodian/alerter'



#
# Unit test for our alerting class
#
# This doesn't actually test the alerts, but it will
# test that we can successfully determine whether a
# destination is inside or outside the Bytemark network.
#
#
class TestAlerter < Test::Unit::TestCase

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

    assert_nothing_raised do
      obj = Alerter.new( {} )
      assert( obj )
    end

  end


  #
  #  Test location-detection.
  #
  def test_locations_inside_outside

    #
    #  Hash of hostnames and version of address.
    #
    to_test = {

      #
      # Hosts inside the Bytemark network
      #
      "www.steve.org.uk"               => true,
      "ipv6.steve.org.uk"              => true,
      "http://www.steve.org.uk/"       => true,
      "http://ipv6.steve.org.uk"       => true,
      "canalrivertrust.org.uk"         => true,
      "http://canalrivertrust.org.uk/" => true,
      "http://canalrivertrust.org.uk"  => true,

      #
      # Hosts outside the Bytemark network
      #
      "https://google.com/"     => false,
      "http://google.com/"      => false,
      "http://ipv6.google.com/" => false,
      "http://192.168.0.333/"   => false,
    }



    to_test.each do |name,inside|

      obj = Alerter.new( nil )

      text = obj.expand_inside_bytemark( name )

      if ( text =~ /is inside/ )
        assert( inside == true )
      end
      if ( text =~ /is not/ )
        assert( inside == false )
      end
    end
  end





end
