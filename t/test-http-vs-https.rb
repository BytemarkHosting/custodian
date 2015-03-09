#!/usr/bin/ruby -Ilib/ -I../lib/


require 'test/unit'

require 'custodian/protocoltests'



#
# Each of our test-objects implements a single test-type, except for http which implements two.
#
# It can be confusing if a test reports the wrong type though:
#
#    http://example.com/ the https test failed against ..
#
# Or in reverse:
#
#    https://example.com/ the http test failed ...
#
# Test we can get the sanest result here.
#
class TestTestName < Test::Unit::TestCase

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
  # Get the type of a test, and ensure it is http.
  #
  def test_http_type
    test = nil

    assert_nothing_raised do
     test = Custodian::TestFactory.create('http://example.com/ must run http.')
    end

    assert(test)
    assert(test.kind_of? Array)
    assert(! test.empty?)
    assert_equal(test[0].get_type, 'http')
  end


  #
  # Get the type of a test, and ensure it is https.
  #
  def test_https_type
    test = nil

    assert_nothing_raised do
     test = Custodian::TestFactory.create('https://example.com/ must run https.')
    end

    assert(test)
    assert(test.kind_of? Array)
    assert(! test.empty?)
    assert_equal(test[0].get_type, 'https')
  end


  #
  # It is a bug to have the protocol-test differ from the URI's protocol.
  #
  def test_protocol_mismatch


    assert_raise ArgumentError do
      Custodian::TestFactory.create('https://example.com/ must run http.')
    end

    assert_raise ArgumentError do
      Custodian::TestFactory.create('http://example.com/ must run https.')
    end


    assert_nothing_raised do
      Custodian::TestFactory.create('http://example.com/ must run http.')
    end
    assert_nothing_raised do
      Custodian::TestFactory.create('https://example.com/ must run https.')
    end

  end

end

