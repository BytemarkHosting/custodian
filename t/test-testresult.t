#!/usr/bin/ruby -Ilib/ -I../lib/


require 'test/unit'

require 'custodian/testfactory'


class TestTestResult < Test::Unit::TestCase

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
  #  Test the passed-symbol
  #
  def test_test_passed
    f = Custodian::TestResult::TEST_PASSED
    assert_equal(Custodian::TestResult.to_str(f), 'TEST_PASSED')
    assert_equal(f, 2)
  end


  #
  #  Test the failed-symbol
  #
  def test_test_failed
    f = Custodian::TestResult::TEST_FAILED
    assert_equal(Custodian::TestResult.to_str(f), 'TEST_FAILED')
    assert_equal(f, 4)
  end

  #
  #  Test the skipped symbol
  #
  def test_test_skipped
    f = Custodian::TestResult::TEST_SKIPPED
    assert_equal(Custodian::TestResult.to_str(f), 'TEST_SKIPPED')
    assert_equal(f, 8)
  end

end
