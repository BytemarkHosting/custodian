#!/usr/bin/ruby -Ilib/ -I../lib/


require 'test/unit'

require 'custodian/protocoltest/tcp.rb'
require 'custodian/protocoltest/dns.rb'
require 'custodian/protocoltest/ftp.rb'
require 'custodian/protocoltest/http.rb'
require 'custodian/protocoltest/jabber.rb'
require 'custodian/protocoltest/ldap.rb'
require 'custodian/protocoltest/ping.rb'
require 'custodian/protocoltest/rsync.rb'
require 'custodian/protocoltest/ssh.rb'
require 'custodian/protocoltest/smtp.rb'



class TestTestFactory < Test::Unit::TestCase

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
  def test_ftp_uri

    assert_nothing_raised do
      assert( Custodian::TestFactory.create( "ftp.example.com must  run ftp." ) )
      assert( Custodian::TestFactory.create( "ftp://ftp.example.com/ must run ftp." ) )
      assert( Custodian::TestFactory.create( "ftp://ftp.example.com/ must run ftp on 21." ) )
      assert( Custodian::TestFactory.create( "ftp://ftp.example.com/ must run ftp on 21 otherwise 'xxx'." ) )
    end


    assert( Custodian::TestFactory.create( "ftp.example.com        must run ftp." ).target() == "ftp.example.com"  )
    assert( Custodian::TestFactory.create( "ftp://ftp.example.com/ must run ftp." ).target() == "ftp.example.com"  )


    #
    #  Test the port detection
    #
    data = {
      "foo must run ftp." => "21",
      "ftp://ftp.example.com/ must run ftp." => "21",
      "foo must run ftp on  1 otherwise 'x'." => "1",
      "foo must run ftp on 33 otherwise"   => "33",
    }

    #
    #  Run each test
    #
    data.each do |str,prt|
      assert_nothing_raised do

        obj = Custodian::TestFactory.create( str )

        #
        #  Ensure we got the object, and the port was correct.
        #
        assert(obj, "created object via TestFactory.create('#{str}')")
        assert( obj.port().to_s == prt , "'#{str}' gave expected port '#{prt}'.")
      end
    end

  end



  #
  # Test the rsync-test creation.
  #
  def test_rsync_uri


    assert_nothing_raised do
      assert( Custodian::TestFactory.create( "example.com must  run rsync." ) )
      assert( Custodian::TestFactory.create( "ftp://example.com/ must run rsync." ) )
      assert( Custodian::TestFactory.create( "ftp://example.com/ must run rsync on 333." ) )
      assert( Custodian::TestFactory.create( "ftp://example.com/ must run rsync on 3311 otherwise 'xxx'." ) )
    end

    assert( Custodian::TestFactory.create( "rsync.example.com  must run rsync." ).target() ==
            "rsync.example.com"  )
    assert( Custodian::TestFactory.create( "rsync://rsync.example.com/ must run rsync." ).target() ==
            "rsync.example.com"  )


    #
    #  Test the ports
    #
    data = {
      "foo must run rsync." => "873",
      "rsync://foo/ must run rsync." => "873",
      "foo must run rsync on 1 otherwise 'x'." => "1",
      "foo must run rsync on 33 otherwise"   => "33",
    }

    #
    #  Run each test
    #
    data.each do |str,prt|
      assert_nothing_raised do

        obj = Custodian::TestFactory.create( str )

        #
        #  Ensure we got the object, and the port was correct.
        #
        assert(obj, "created object via TestFactory.create('#{str}')")
        assert( obj.port().to_s == prt , "'#{str}' gave expected port '#{prt}'.")
      end
    end
  end




  #
  # Test the DNS test may be created
  #
  def test_dns_handler

    assert_nothing_raised do
      assert( Custodian::TestFactory.create( "a.ns.bytemark.co.uk must run dns for bytemark.co.uk resolving NS as '80.68.80.26;85.17.170.78;80.68.80.27'." ) )
    end

    #
    #  Missing record-type
    #
    assert_raise ArgumentError do
      Custodian::TestFactory.create( "a.ns.bytemark.co.uk must run dns for bytemark.co.uk as '80.68.80.26;85.17.170.78;80.68.80.27'." )
    end

    #
    #  Missing target
    #
    assert_raise ArgumentError do
      assert( Custodian::TestFactory.create( "a.ns.bytemark.co.uk must run dns resolving NS as '80.68.80.26;85.17.170.78;80.68.80.27'." ) )
    end

    #
    #  Missing expected results
    #
    assert_raise ArgumentError do
      assert( Custodian::TestFactory.create( "a.ns.bytemark.co.uk must run dns for www.bytemark.co.uk resolving NS " ) )
    end
  end




  #
  # Test the creation of inverted tests.
  #
  def test_inverted_tests


    assert_nothing_raised do
      assert( Custodian::TestFactory.create( "example.com must not run rsync." ) )
      assert( Custodian::TestFactory.create( "ftp://example.com/ must not run rsync." ) )
      assert( Custodian::TestFactory.create( "ftp://example.com/ must not run rsync on 333." ) )
    end


    #
    #  Test some inversions
    #
    data = {
      "foo must run rsync."              => false,
      "rsync://foo/ must run rsync."     => false,
      "foo must run ping otherwise"      => false,
      "foo must not run ping otherwise"  => true,
      "foo must not run ssh otherwise"   => true,
      "foo must not run ldap otherwise"  => true,
    }

    #
    #  Run each test
    #
    data.each do |str,inv|
      assert_nothing_raised do

        obj = Custodian::TestFactory.create( str )

        #
        #  Ensure we got the object, and the port was correct.
        #
        assert(obj, "created object via TestFactory.create('#{str}')")
        assert( obj.inverted() == inv, "#{str} -> #{inv}" )
      end
    end

  end

  #
  # Get all the types we know about.
  #
  def test_types
    registered = Custodian::TestFactory.known_tests()

    registered.each do |obj|


      #
      #  Try to get the name
      #
      name=obj.to_s
      if ( name =~ /protocoltest::(.*)Test$/i )
        tst = $1.dup.downcase

        #
        # NOTE: Skip the DNS test - it is more complex.
        #
        next if ( tst =~ /dns/ )

        # normal
        test_one = "http://foo/ must run #{tst} on 1234"
        test_two = "http://foo/ must not run #{tst} on 12345"

        assert_nothing_raised do

          test_one_obj = Custodian::TestFactory.create( test_one )
          assert( !test_one_obj.inverted() )

          test_two_obj = Custodian::TestFactory.create( test_two )
          assert( test_two_obj.inverted(), "Found inverted test for #{tst}" )
        end
      end
    end
  end

end

