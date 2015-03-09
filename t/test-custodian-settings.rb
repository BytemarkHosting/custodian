#!/usr/bin/ruby -I./lib/ -I../lib/


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
    a = Custodian::Settings.instance
    b = Custodian::Settings.instance

    assert( a )
    assert( b )
    assert_equal( a.object_id, b.object_id )
  end


  #
  #  Test that our settings are suitable types
  #
  def test_types
    settings = Custodian::Settings.instance


    # retry delay - probably unset.
    a = settings.retry_delay
    assert( a.class == Fixnum )

    # store a number
    settings._store( 'retry_delay', 5 )
    a = settings.retry_delay
    assert( a.class == Fixnum )
    assert( a == 5 )

    # store a string
    settings._store( 'retry_delay', '35' )
    a = settings.retry_delay
    assert( a.class == Fixnum )
    assert( a == 35 )



    # timeout - probably unset.
    a = settings.timeout
    assert( a.class == Fixnum )

    # store a number
    settings._store( 'timeout', 5 )
    a = settings.timeout
    assert( a.class == Fixnum )
    assert( a == 5 )

    # store a string
    settings._store( 'timeout', '35' )
    a = settings.timeout
    assert( a.class == Fixnum )
    assert( a == 35 )


  end

end
