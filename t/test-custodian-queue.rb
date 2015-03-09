#!/usr/bin/ruby -I./lib/ -I../lib/


require 'test/unit'
require 'custodian/queue'




#
# Unit test for our queue-factory.
#
class TestCustodianQueue < Test::Unit::TestCase




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
  # Test that creating an unknown type throws an exception.
  #
  def test_unknown

    # creation will fail
    assert_raise RuntimeError do
      t = Custodian::QueueType.create('foo')
    end

  end



  def test_redis
    q = nil
    assert_nothing_raised do
      q = Custodian::QueueType.create('redis')
    end

    #
    # here we're testing we've got a derived class that has
    # implemented the methods "size?" & "flush!"
    #
    assert_nothing_raised do
      q.size?
      q.flush!
    end

  end


  def test_beanstalkd
    q = nil
    assert_nothing_raised do
      q = Custodian::QueueType.create('redis')
    end

    #
    # here we're testing we've got a derived class that has
    # implemented the methods "size?" & "flush!"
    #
    assert_nothing_raised do
      q.size?
      q.flush!
    end


  end

end
