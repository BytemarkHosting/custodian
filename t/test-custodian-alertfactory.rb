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
    methods = []
    methods.push('file')
    methods.push('smtp')

    #
    # Mauve + Redis are optional
    #
    redis = true
    mauve = true

    begin
      require 'rubygems'
      require 'redis'
    rescue LoadError => ex
      redis = false
    end

    begin
      require 'mauve/sender'
      require 'mauve/proto'
    rescue LoadError => ex
      mauve = false
    end

    methods.push('redis') if  redis
    methods.push('mauve') if  mauve

    methods.each do |name|

      #
      #  Use the factory to instantiate the correct object.
      #
      obj = Custodian::AlertFactory.create(name, nil)

      #
      # Get the name of the class, and ensure it matches
      # what we expect.
      #
      a_type = obj.get_type
      assert_equal(name, a_type)

      #
      # Ensure that the object implements the raise() + clear()
      # methods we mandate.
      #
      assert(obj.respond_to? 'raise')
      assert(obj.respond_to? 'clear')
    end


    #
    # Creating an alert we don't know about is an error
    #
    assert_raise ArgumentError do
      obj = Custodian::AlertFactory.create('not found', nil)
    end

    #
    # A string is mandatory
    #
    assert_raise ArgumentError do
      obj = Custodian::AlertFactory.create(nil, nil)
    end
    assert_raise ArgumentError do
      obj = Custodian::AlertFactory.create([], nil)
    end

  end

end

