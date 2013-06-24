#!/usr/bin/ruby1.8 -I./lib/ -I../lib/


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
  #  Ensure we received errors if the start/end hours are under/over 24
  #
  def test_excessive_hours

    #
    #  Valid hours are 0-23, inclusive.  Test outside that range.
    #
    for i in  24..100
      assert_raise ArgumentError do
        result = Custodian::Util::TimeSpan.inside?( i, 2 )
      end

      assert_raise ArgumentError do
        result = Custodian::Util::TimeSpan.inside?( 1, i )
      end
    end

    #
    #  Now negative values.
    #
    for i in 1..50
      assert_raise ArgumentError do
        result = Custodian::Util::TimeSpan.inside?( 1, ( -1 * i ) )
      end
      assert_raise ArgumentError do
        result = Custodian::Util::TimeSpan.inside?(  ( -1 * i ), 1 )
      end
    end

  end


  #
  #  Test simple cases where the period is positive.
  #
  def test_simple_cases
    # 8am-5pm
    assert(Custodian::Util::TimeSpan.inside?( "8am", "5am", 12 ))
    assert(Custodian::Util::TimeSpan.inside?( 8, 17, 12 ))

  end

  #
  #  Test cases which involve the wrap-around over midnight.
  #
  def test_midnight_cases

    # 9pm-2am
    assert(Custodian::Util::TimeSpan.inside?( "9pm", "2am", 22 ))
    assert(Custodian::Util::TimeSpan.inside?( "9pm", "2am", "10pm" ))
    assert(Custodian::Util::TimeSpan.inside?( 21, 2, 22 ))
    assert(Custodian::Util::TimeSpan.inside?( 21, 2, "10pm" ))

    # 10pm-3am
    assert(Custodian::Util::TimeSpan.inside?( "10pm", "3am", 22 ))
    assert(Custodian::Util::TimeSpan.inside?( 22, 3, 22 ))
    assert(Custodian::Util::TimeSpan.inside?( 22, 3, 22 ))
    assert(Custodian::Util::TimeSpan.inside?( 22, 3, "10pm" ))

    # 11pm-5am
    assert(Custodian::Util::TimeSpan.inside?( "11pm", "5am", 23 ))
    assert(Custodian::Util::TimeSpan.inside?( 23, 5, 23 ))
    assert(Custodian::Util::TimeSpan.inside?( "11pm", "5am", "11pm" ))

    # midnight-3am
    assert( Custodian::Util::TimeSpan.inside?( "0", "3am", 1 ))
    assert( Custodian::Util::TimeSpan.inside?( "0", "3am", "1am" ))
  end


  #
  #  The time-spans listed are inclusive.
  #
  #  Test the boundaries.
  #
  def test_inclusive

    open = "4pm"
    close = "6pm"

    # The hours + the middle should be inside
    assert( Custodian::Util::TimeSpan.inside?( open, close, 16 ) )
    assert( Custodian::Util::TimeSpan.inside?( open, close, "4pm" ) )

    assert( Custodian::Util::TimeSpan.inside?( open, close, 17 ) )
    assert( Custodian::Util::TimeSpan.inside?( open, close, "5pm" ) )

    assert( Custodian::Util::TimeSpan.inside?( open, close, 18 ) )
    assert( Custodian::Util::TimeSpan.inside?( open, close, "6pm" ) )


    #
    # The preceeding + successive hours shouldn't be.
    #
    assert( ! Custodian::Util::TimeSpan.inside?( open, close, 15 ) )
    assert( ! Custodian::Util::TimeSpan.inside?( open, close, 19 ) )

    #
    # That is true for the string-versions too
    #
    assert( ! Custodian::Util::TimeSpan.inside?( open, close, "3pm" ) )
    assert( ! Custodian::Util::TimeSpan.inside?( open, close, "7pm" ) )


    #
    # Random hours should be outside too.
    #
    assert( ! Custodian::Util::TimeSpan.inside?( open, close, 3 ) )
    assert( ! Custodian::Util::TimeSpan.inside?( open, close, "3am" ) )
    assert( ! Custodian::Util::TimeSpan.inside?( open, close, 7 ) )
    assert( ! Custodian::Util::TimeSpan.inside?( open, close, "7am" ) )
    assert( ! Custodian::Util::TimeSpan.inside?( open, close, 9 ) )
    assert( ! Custodian::Util::TimeSpan.inside?( open, close, "9am" ) )

  end

end
