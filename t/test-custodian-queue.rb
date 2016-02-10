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
    unless defined? ::Redis
      if methods.include? :skip
        skip("Redis library missing -- skipping tests")
      else
        omit("Redis library missing -- skipping tests")
      end
    end
  end




  #
  # Destroy the test suite environment: NOP.
  #
  def teardown
  end


  #
  #  Test we can create and use a Redis queue.
  #
  def test_redis

    q = nil
    assert_nothing_raised do
      q = Custodian::RedisQueueType.new()
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
