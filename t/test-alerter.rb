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
  def test_location_detection

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
      if ( text =~ /OUTSIDE/ )
        assert( inside == false )
      end
    end

    #
    # OK now look for the text returned
    #
    obj = Alerter.new( nil )
    details = obj.expand_inside_bytemark( "46.43.50.217" )
    assert( details.match( /46.43.50.217 is inside the Bytemark network/ ) )

    details = obj.expand_inside_bytemark( "www.linnrecords.com" )
    assert( details.match( /resolves to 46.43.50.217 which is inside the Bytemark network/ ) )

  end



  #
  #  Test documentation-detection.
  #
  def test_locations_inside_outside

    obj = Alerter.new( nil )

    assert_raise ArgumentError do
      obj.document_address( nil )
    end

    #
    # IPv6 lookup
    #
    details = obj.document_address( "2001:41c8:125:46::22" )
    assert( details =~ /ssh.steve.org.uk/i )

    #
    # IPv4 lookup
    #
    details = obj.document_address( "80.68.85.48" )
    assert( details =~ /ssh.steve.org.uk/i )

    #
    # Bogus lookup - should return nil.
    #
    details = obj.document_address( "800.683.853.348" )
    assert( details.nil? )

  end
end
