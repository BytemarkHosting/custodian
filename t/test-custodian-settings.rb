#!/usr/bin/ruby1.8 -I./lib/ -I../lib/


require 'custodian/settings'
require 'test/unit'



#
# Unit test for our configuration file reader.
#
#
class TestConfigurationSingleton < Test::Unit::TestCase

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
  # Test that we're genuinely a singleton
  #
  def test_singleton
    a = Custodian::Settings.instance()
    b = Custodian::Settings.instance()

    assert( a )
    assert( b )
    assert_equal( a.object_id, b.object_id )
  end


end
