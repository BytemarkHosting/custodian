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



    assert( Custodian::TestFactory.create( "rsync.example.com        must run rsync." ).target() == "rsync.example.com"  )
    assert( Custodian::TestFactory.create( "rsync://rsync.example.com/ must run rsync." ).target() == "rsync.example.com"  )


  end


end

