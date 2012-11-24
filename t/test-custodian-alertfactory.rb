#!/usr/bin/ruby -Ilib/ -I../lib/


require 'test/unit'

require 'custodian/alerts'



class TestAlertFactory < Test::Unit::TestCase

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
  # Test the FTP-test may be created
  #
  def test_alert_creation

    #
    # Ensure we can create each of the two alert types we care about
    #
    %w( file mauve smtp ).each do |name|

      #
      #  Use the factory to instantiate the correct object.
      #
      obj = Custodian::AlertFactory.create( name, nil )

      #
      # Get the name of the class, and ensure it matches
      # what we expect.
      #
      a_type = obj.get_type
      assert_equal( name, a_type)

      #
      # Ensure that the object implements the raise() + clear()
      # methods we mandate.
      #
      assert( obj.respond_to? "raise" )
      assert( obj.respond_to? "clear" )
    end
  end

end

