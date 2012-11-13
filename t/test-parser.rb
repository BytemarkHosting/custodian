#!/usr/bin/ruby -I../bin/ -Ibin/


require 'test/unit'
require 'custodian-enqueue'



#
# Unit test for our parser.
#
class TestParser < Test::Unit::TestCase

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
  #  Test we can create a new parser object - specifically
  # that it throws exceptions if it is not given a filename
  # that exists.
  #
  def test_init

    #
    #  Missing filename -> Exception
    #
    assert_raise ArgumentError do
      MonitorConfig.new()
    end

    #
    #  Filename points to file that doesn't exist -> Exception
    #
    assert_raise ArgumentError do
      MonitorConfig.new("/file/doesn't/exist")
    end

    #
    #  File that exists -> No Exception.
    #
    assert_nothing_raised do
      MonitorConfig.new("/dev/null" )
    end

  end


  #
  #  Test that we can define macros.
  #
  def test_macros

    parser = MonitorConfig.new("/dev/null" )

    #
    #  With nothing loaded we should have zero macros - so the
    # count of our macros hash should be zero
    #
    macros = parser.macros
    assert( macros.empty? )
    assert( macros.size() == 0 )


    #
    #  Define a macro:
    #
    #  FOO =>  "kvm1.vm.bytemark.co.uk", "kvm2.vm.bytemark.co.uk".
    #
    #  Before defining it double-check it doesn't exist
    #
    assert( !(parser.is_macro?( "FOO" )) )

    parser.define_macro( "FOO is kvm1.vm.bytemark.co.uk and kvm2.vm.bytemark.co.uk." )


    #
    #  OK we should now have a single macro defined.
    #
    macros = parser.macros
    assert( macros.size() == 1 )

    #
    #  The macro name "FOO" should exist
    #
    assert( parser.is_macro?( "FOO" ) )

    #
    #  The contents of the FOO macro should have the value we expect
    #
    val = parser.get_macro_targets( "FOO" )
    assert( val.size() == 2 )
    assert( val.include?( "kvm1.vm.bytemark.co.uk" ) )
    assert( val.include?( "kvm2.vm.bytemark.co.uk" ) )
  end


end
