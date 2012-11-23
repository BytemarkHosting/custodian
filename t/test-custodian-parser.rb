#!/usr/bin/ruby1.8 -I./lib/ -I../lib/


require 'test/unit'
require 'custodian/parser'




#
# Unit test for our parser.
#
class TestCustodianParser < Test::Unit::TestCase

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
    #  Constructor
    #
    assert_nothing_raised do
      Custodian::Parser.new()
    end
  end



  #
  #  Test that we can define macros.
  #
  def test_macros_lines

    parser = Custodian::Parser.new()

    #
    #  Input text
    #
    text =<<EOF
FOO is  kvm1.vm.bytemark.co.uk.
TEST is kvm2.vm.bytemark.co.uk.
EOF

    #
    # Test the parser with this text
    #
    parser.parse_lines( text )


    #
    #  We should now have two macros.
    #
    macros = parser.macros
    assert( ! macros.empty? )
    assert( macros.size() == 2 )
  end



  #
  #  Test that we can define macros.
  #
  def test_macros_array

    parser = Custodian::Parser.new()

    #
    #  Input text
    #
    text = Array.new()
    text.push( "FOO  is  kvm1.vm.bytemark.co.uk." );
    text.push( "FOO2 is  kvm2.vm.bytemark.co.uk." );

    #
    # Test the parser with this text
    #
    parser.parse_lines( text )


    #
    #  We should now have two macros.
    #
    macros = parser.macros
    assert( ! macros.empty? )
    assert( macros.size() == 2 )
  end



  #
  # Duplicate macros are a bug
  #
  def test_duplicate_macros

    parser = Custodian::Parser.new()

    #
    #  Input text
    #
    text = Array.new()
    text.push( "FOO  is  kvm1.vm.bytemark.co.uk." );
    text.push( "FOO is  kvm2.vm.bytemark.co.uk." );

    #
    # Test the parser with this text
    #
    assert_raise ArgumentError do
      parser.parse_lines( text )
    end


    #
    #  We should now have one macros.
    #
    macros = parser.macros
    assert( ! macros.empty? )
    assert( macros.size() == 1 )
  end


end
