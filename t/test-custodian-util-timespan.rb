#!/usr/bin/ruby -I./lib/ -I../lib/


require 'custodian/util/timespan'
require 'test/unit'



#
# Unit test for our time-span code.
#
class TestTimeSpanUtil < Test::Unit::TestCase

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
  #  Test the expansion of "obvious" hour-specifiers.
  #
  def test_to_hour

    for hour in 0..23
      assert_equal(hour, Custodian::Util::TimeSpan.to_hour(hour))
    end

    #
    #  Invalid hours will throw exceptions
    #
    assert_raise ArgumentError do
      result = Custodian::Util::TimeSpan.to_hour(0.5)
    end
    assert_raise ArgumentError do
      result = Custodian::Util::TimeSpan.to_hour(-1)
    end
    assert_raise ArgumentError do
      result = Custodian::Util::TimeSpan.to_hour(100)
    end
    assert_raise ArgumentError do
      result = Custodian::Util::TimeSpan.to_hour(24)
    end
    assert_raise ArgumentError do
      result = Custodian::Util::TimeSpan.to_hour(25)
    end

    #
    #  Ensure AM times work well
    #
    for hour in 0..11
      assert_equal(hour, Custodian::Util::TimeSpan.to_hour("#{hour}am"))
    end

    for hour in 0..11
      assert_equal(12 +hour, Custodian::Util::TimeSpan.to_hour("#{hour}pm"))
    end

  end


  #
  #
  #  Ensure we received errors if the start/end hours are under/over 24
  #
  def test_excessive_hours

    #
    #  Valid hours are 0-23, inclusive.  Test outside that range.
    #
    for i in  24..100
      assert_raise ArgumentError do
        result = Custodian::Util::TimeSpan.inside?(i, 2)
      end

      assert_raise ArgumentError do
        result = Custodian::Util::TimeSpan.inside?(1, i)
      end

      assert_raise ArgumentError do
        result = Custodian::Util::TimeSpan.inside?(1, 2, i)
      end
    end

    #
    #  Now negative values.
    #
    for i in 1..50

      assert_raise ArgumentError do
        result = Custodian::Util::TimeSpan.inside?(1, (-1 * i))
      end

      assert_raise ArgumentError do
        result = Custodian::Util::TimeSpan.inside?((-1 * i), 1)
      end

      assert_raise ArgumentError do
        result = Custodian::Util::TimeSpan.inside?(1, 1, (-1 * i))
      end
    end

  end


  #
  #  Test simple cases where the period is positive.
  #
  def test_simple_cases
    # 8am-5pm
    assert(Custodian::Util::TimeSpan.inside?('8am', '5am', 12))
    assert(Custodian::Util::TimeSpan.inside?(8, 17, 12))

  end

  #
  #  Test cases which involve the wrap-around over midnight.
  #
  def test_midnight_cases

    # 9pm-2am
    assert(Custodian::Util::TimeSpan.inside?('9pm', '2am', 22))
    assert(Custodian::Util::TimeSpan.inside?('9pm', '2am', '10pm'))
    assert(Custodian::Util::TimeSpan.inside?(21, 2, 22))
    assert(Custodian::Util::TimeSpan.inside?(21, 2, '10pm'))

    # 10pm-3am
    assert(Custodian::Util::TimeSpan.inside?('10pm', '3am', 22))
    assert(Custodian::Util::TimeSpan.inside?(22, 3, 22))
    assert(Custodian::Util::TimeSpan.inside?(22, 3, 22))
    assert(Custodian::Util::TimeSpan.inside?(22, 3, '10pm'))

    # 11pm-5am
    assert(Custodian::Util::TimeSpan.inside?('11pm', '5am', 23))
    assert(Custodian::Util::TimeSpan.inside?(23, 5, 23))
    assert(Custodian::Util::TimeSpan.inside?('11pm', '5am', '11pm'))

    # midnight-3am
    assert(Custodian::Util::TimeSpan.inside?('0', '3am', 1))
    assert(Custodian::Util::TimeSpan.inside?('0', '3am', '1am'))
  end


  #
  #  The time-spans listed are inclusive.
  #
  #  Test the boundaries.
  #
  def test_inclusive

    open = '4pm'
    close = '6pm'

    # The hours + the middle should be inside
    assert(Custodian::Util::TimeSpan.inside?(open, close, 16))
    assert(Custodian::Util::TimeSpan.inside?(open, close, '4pm'))

    assert(Custodian::Util::TimeSpan.inside?(open, close, 17))
    assert(Custodian::Util::TimeSpan.inside?(open, close, '5pm'))

    assert(Custodian::Util::TimeSpan.inside?(open, close, 18))
    assert(Custodian::Util::TimeSpan.inside?(open, close, '6pm'))


    #
    # The preceeding + successive hours shouldn't be.
    #
    assert(! Custodian::Util::TimeSpan.inside?(open, close, 15))
    assert(! Custodian::Util::TimeSpan.inside?(open, close, 19))

    #
    # That is true for the string-versions too
    #
    assert(! Custodian::Util::TimeSpan.inside?(open, close, '3pm'))
    assert(! Custodian::Util::TimeSpan.inside?(open, close, '7pm'))


    #
    # Random hours should be outside too.
    #
    assert(! Custodian::Util::TimeSpan.inside?(open, close, 3))
    assert(! Custodian::Util::TimeSpan.inside?(open, close, '3am'))
    assert(! Custodian::Util::TimeSpan.inside?(open, close, 7))
    assert(! Custodian::Util::TimeSpan.inside?(open, close, '7am'))
    assert(! Custodian::Util::TimeSpan.inside?(open, close, 9))
    assert(! Custodian::Util::TimeSpan.inside?(open, close, '9am'))

  end


  #
  #  Since the implementation of our test involves
  # iterating over the specified period then any 24-hour
  # period is the worst case.
  #
  #
  def test_worst
    for i in 0..23
      assert(Custodian::Util::TimeSpan.inside?(0, 23, i))
    end
  end

  #
  #  Test that we don't wrap-around unexpectedly.
  #
  #
  #  i.e. "between 00-00" is one hour, not 24.
  #
  def test_wrap_around

    for h in 00..23
      assert_equal(1, Custodian::Util::TimeSpan.to_hours(h,h).size)
    end

    #
    #  But the time-period 00-23 is a full day
    #
    assert_equal(24,
                 Custodian::Util::TimeSpan.to_hours(0,23).size)

  end


end
