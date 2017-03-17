#!/usr/bin/ruby -I./lib/ -I../lib/


require 'custodian/util/dns'
require 'test/unit'
require 'pp'


#
# Unit test for our DNS utility class.
#
#
class TestDNSUtil < Test::Unit::TestCase

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
  #  Test forward lookups
  #
  def test_lookup
    return unless ENV['GITLAB_CI'].nil?

    details = Custodian::Util::DNS.hostname_to_ip('bytemark.co.uk')
    assert((details == '2001:41c9:0:1019:81::80') ||
            (details == '80.68.81.80'))

    details = Custodian::Util::DNS.hostname_to_ip('www.bytemark.co.uk')
    assert((details == '2001:41c9:0:1019:81::80') ||
            (details == '80.68.81.80'))


    #
    # Failure case
    #
    details = Custodian::Util::DNS.hostname_to_ip('this.doesnot.exist')
    assert(details.nil?)

  end


  #
  #  Test forward lookups
  #
  def test_reverse_lookup
    return unless ENV['GITLAB_CI'].nil?

    #
    # IPv6 lookup
    #
    details = Custodian::Util::DNS.ip_to_hostname('2001:41c9:0:1019:81::80')
    assert(details =~ /bytemark(-?hosting)?\.(com|eu|co\.uk)$/i)

    #
    # IPv4 lookup
    #
    details = Custodian::Util::DNS.ip_to_hostname('80.68.81.80')
    assert(details =~ /bytemark(-?hosting)?\.(com|eu|co\.uk)$/i)

    #
    # Bogus lookup - should return nil.
    #
    details = Custodian::Util::DNS.ip_to_hostname('800.683.853.348')
    assert(details.nil?)
  end

end
