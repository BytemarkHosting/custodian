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
    %w( mauve smtp ).each do |name|
      obj = Custodian::AlertFactory.create( name, nil )

      #
      # Get the name of the class, and ensure it matches
      # what we expect.
      #
      a_type = obj.get_type
      assert_equal( name, a_type)
    end
  end

end

