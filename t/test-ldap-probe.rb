#!/usr/bin/ruby -Ilib/ -I../lib/


require 'test/unit'

require 'custodian/protocoltests'



class TestLDAPProbe < Test::Unit::TestCase

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
  # Test the sanity of a good test.
  #
  def test_expected_usage
    test = nil

    assert_nothing_raised do
     test = Custodian::TestFactory.create("auth.bytemark.co.uk must run ldap on 389 with username 'testing' with password 'bob' otherwise 'LDAP dead?'.")
    end

    assert(test.kind_of? Array)
    assert(!test.empty?)
    assert_equal(test[0].get_type, 'ldap')
  end



  #
  #  Ensure missing a test raises an error.
  #
  def test_missing_ldap
    #
    # test data
    #
    data = [
            'foo.example.com must run ldap on 389.',
            "foo.example.com must run ldap with username 'test'.",
            "foo.example.com must run ldap with uername 'test' with password 'x'."
    ]

    #
    #  For each test
    #
    data.each do |str|
      assert_raise ArgumentError do
        test = Custodian::TestFactory.create(str)

        assert(test.kind_of? Array)
        assert(!test.empty?)

      end
    end
  end

end
