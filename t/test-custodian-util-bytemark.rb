#!/usr/bin/ruby -I./lib/ -I../lib/


require 'custodian/util/bytemark'
require 'test/unit'



#
# Unit test for our Bytemark utility class.
#
#
class TestBytemarkUtil < Test::Unit::TestCase

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
  # Test that we receive sensible results from the static inside? method
  #
  def test_ranges

    #
    #  Hash of hostnames and the expected result.
    #
    to_test = {

      #
      # Hosts inside the Bytemark network
      #
      "80.68.85.48"               => true,
      "2001:41c8:125:46::10"      => true,

      #
      # Hosts outside the Bytemark network
      #
      "127.0.0.1"                 => false,
      "192.168.1.1"               => false,
      "2a00:1450:400c:c00::93"    => false,
    }


    to_test.each do |name,inside|

      if  inside 
        assert( Custodian::Util::Bytemark.inside?( name ) == true  )
      else
        assert( Custodian::Util::Bytemark.inside?( name ) == false  )
      end
    end

  end


end
