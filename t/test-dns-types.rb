#!/usr/bin/ruby -Ilib/ -I../lib/


require 'test/unit'
require 'mocha/test_unit'
require 'custodian/protocoltests'



#
# The DNS test is a complex one.
#
class TestDNSTypes < Test::Unit::TestCase

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
  # Test the known-record types: A, NS, MX, AAAA
  #
  def test_known_types

    assert_nothing_raised do
     test = Custodian::TestFactory.create( "a.ns.bytemark.co.uk must run dns for bytemark.co.uk resolving NS as 'foo'." )
     test = Custodian::TestFactory.create( "a.ns.bytemark.co.uk must run dns for bytemark.co.uk resolving A as 'foo'." )
     test = Custodian::TestFactory.create( "a.ns.bytemark.co.uk must run dns for bytemark.co.uk resolving MX as 'foo'." )
     test = Custodian::TestFactory.create( "a.ns.bytemark.co.uk must run dns for bytemark.co.uk resolving AAAA as 'foo'." )
    end

  end



  #
  # Test that using random types fails.
  #
  def test_unknown_types

    #
    #  Each of these will fail
    #
    %w( a ns www example fdskfjdlfsj `` ).each do |res|
      assert_raise ArgumentError do
        Custodian::TestFactory.create( "a.ns.bytemark.co.uk must run dns for bytemark.co.uk resolving #{res} as 'foo'." )
      end
    end
  end

  #
  # Now test the protocol stuff, without doing the resolution itself.
  #
  def test_dns_protocol_test
     test = Custodian::TestFactory.create( "a.ns.bytemark.co.uk must run dns for bytemark.co.uk resolving A as '1.2.3.4,2001:lower::case,2001:UPPER::CASE'." )
     test.stubs(:resolve_via).returns(%w(2001:lower::case 2001:upper::case 1.2.3.4))
     assert test.run_test, test.error
    
     # Re-stub to return just one record 
     test.stubs(:resolve_via).returns(%w(1.2.3.4))
     assert !test.run_test
     
     # Re-stub to return too many records
     test.stubs(:resolve_via).returns(%w(2001:lower::case 2001:upper::case 1.2.3.4 1.2.3.5))
     assert !test.run_test

     # Re-stub to return no records
     test.stubs(:resolve_via).returns([])
     assert !test.run_test
  end

end

