#!/usr/bin/ruby -Ilib/ -I../lib/


require 'test/unit'

require 'custodian/protocoltests'



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
  # Test bogus creation
  #
  def test_init

    assert_raise ArgumentError do
      obj = Custodian::TestFactory.create(nil, nil)
    end

    assert_raise ArgumentError do
      obj = Custodian::TestFactory.create([], nil)
    end


  end


  #
  # Test the FTP-test may be created
  #
  def test_ftp_uri

    assert_nothing_raised do
      assert(Custodian::TestFactory.create('ftp.example.com must  run ftp.'))
      assert(Custodian::TestFactory.create('ftp://ftp.example.com/ must run ftp.'))
      assert(Custodian::TestFactory.create('ftp://ftp.example.com/ must run ftp on 21.'))
      assert(Custodian::TestFactory.create("ftp://ftp.example.com/ must run ftp on 21 otherwise 'xxx'."))
    end


    assert(Custodian::TestFactory.create('ftp.example.com        must run ftp.')[0].target == 'ftp.example.com')
    assert(Custodian::TestFactory.create('ftp://ftp.example.com/ must run ftp.')[0].target == 'ftp.example.com')


    #
    #  Test the port detection
    #
    data = {
      'foo must run ftp.' => '21',
      'ftp://ftp.example.com/ must run ftp.' => '21',
      "foo must run ftp on  1 otherwise 'x'." => '1',
      'foo must run ftp on 33 otherwise'   => '33',
    }

    #
    #  Run each test
    #
    data.each do |str, prt|
      assert_nothing_raised do

        obj = Custodian::TestFactory.create(str)

        assert(obj.kind_of? Array)
        assert(!obj.empty?)
        assert_equal(obj[0].get_type, 'ftp')
        assert_equal(obj[0].port.to_s, prt)

      end
    end

  end



  #
  # Test port-guessing.
  #
  def test_port_detection
    data = {
      'foo must run ftp.' => '21',
      'foo must run ssh.' => '22',
      "foo must run mysql otherwise 'alert'"   => '3306',
      "foo must run redis otherwise 'alert'"   => '6379',
      "foo must run rEDIs otherwise 'alert'"   => '6379',
      "foo must run rdp otherwise 'alert'"   => '3389',
      "foo must run RDP otherwise 'alert'"   => '3389',
      "foo must run mysql on 33 otherwise 'alert'"   => '33',
    }

    #
    #  Run each test
    #
    data.each do |str, prt|
      assert_nothing_raised do

        obj = Custodian::TestFactory.create(str)

        assert(obj)
        assert(obj.kind_of? Array)
        assert(!obj.empty?)
        assert(obj[0].port.to_s == prt, "'#{str}' gave expected port '#{prt}'.")
      end
    end

  end



  #
  # Test the rsync-test creation.
  #
  def test_rsync_uri


    assert_nothing_raised do
      assert(Custodian::TestFactory.create('example.com must  run rsync.'))
      assert(Custodian::TestFactory.create('ftp://example.com/ must run rsync.'))
      assert(Custodian::TestFactory.create('ftp://example.com/ must run rsync on 333.'))
      assert(Custodian::TestFactory.create("ftp://example.com/ must run rsync on 3311 otherwise 'xxx'."))
    end

    assert(Custodian::TestFactory.create('rsync.example.com  must run rsync.')[0].target ==
            'rsync.example.com')
    assert(Custodian::TestFactory.create('rsync://rsync.example.com/ must run rsync.')[0].target ==
            'rsync.example.com')


    #
    #  Test the ports
    #
    data = {
      'foo must run rsync.' => '873',
      'rsync://foo/ must run rsync.' => '873',
      "foo must run rsync on 1 otherwise 'x'." => '1',
      'foo must run rsync on 33 otherwise'   => '33',
    }

    #
    #  Run each test
    #
    data.each do |str, prt|
      assert_nothing_raised do

        obj = Custodian::TestFactory.create(str)

        assert(obj.kind_of? Array)
        assert(!obj.empty?)
        assert(obj[0].port.to_s == prt, "'#{str}' gave expected port '#{prt}'.")
      end
    end
  end




  #
  # Test the DNS test may be created
  #
  def test_dns_handler

    assert_nothing_raised do
      assert(Custodian::TestFactory.create("a.ns.bytemark.co.uk must run dns for bytemark.co.uk resolving NS as '80.68.80.26;85.17.170.78;80.68.80.27'."))
    end

    #
    #  Missing record-type
    #
    assert_raise ArgumentError do
      Custodian::TestFactory.create("a.ns.bytemark.co.uk must run dns for bytemark.co.uk as '80.68.80.26;85.17.170.78;80.68.80.27'.")
    end

    #
    #  Missing target
    #
    assert_raise ArgumentError do
      assert(Custodian::TestFactory.create("a.ns.bytemark.co.uk must run dns resolving NS as '80.68.80.26;85.17.170.78;80.68.80.27'."))
    end

    #
    #  Missing expected results
    #
    assert_raise ArgumentError do
      assert(Custodian::TestFactory.create('a.ns.bytemark.co.uk must run dns for www.bytemark.co.uk resolving NS '))
    end
  end




  #
  # Test the creation of inverted tests.
  #
  def test_inverted_tests


    assert_nothing_raised do
      assert(Custodian::TestFactory.create('example.com must not run rsync.'))
      assert(Custodian::TestFactory.create('ftp://example.com/ must not run rsync.'))
      assert(Custodian::TestFactory.create('ftp://example.com/ must not run rsync on 333.'))
    end


    #
    #  Test some inversions
    #
    data = {
      'foo must run rsync.'              => false,
      'rsync://foo/ must run rsync.'     => false,
      'foo must run ping otherwise'      => false,
      'foo must not run ping otherwise'  => true,
      'foo must not run ssh otherwise'   => true,
    }

    #
    #  Run each test
    #
    data.each do |str, inv|
      assert_nothing_raised do

        obj = Custodian::TestFactory.create(str)

        assert(obj.kind_of? Array)
        assert(!obj.empty?)

        #
        #  Ensure we got the object, and the port was correct.
        #
        assert(obj, "created object via TestFactory.create('#{str}')")
        assert(obj[0].inverted? == inv, "#{str} -> #{inv}")
      end
    end

  end

  #
  # Get all the types we know about.
  #
  def test_types
    registered = Custodian::TestFactory.known_tests

    # for each test-type
    registered.keys.each do |type|

      # for each handler ..
      registered[type].each do |name|

        if  name.to_s =~ /protocoltest::(.*)Test$/i
          tst = $1.dup.downcase

          #
          # NOTE: Skip the DNS and LDAP tests - they are more complex.
          #
          next if  tst =~ /^(ldap|dns|dnsbl|sslcertificate)$/

          # normal
          test_one = "http://foo.com/.com must run #{tst} on 1234"
          test_two = "http://foo.com/ must not run #{tst} on 12345"

          assert_nothing_raised do

            test_one_obj = Custodian::TestFactory.create(test_one)
            assert(!test_one_obj[0].inverted?)

            test_two_obj = Custodian::TestFactory.create(test_two)
            assert(test_two_obj[0].inverted?, "Found inverted test for #{tst}")

            assert_equal(tst, test_one_obj[0].get_type)
            assert_equal(tst, test_two_obj[0].get_type)
          end
        end
      end
    end
  end


  #
  # Test the target of each test is always what we expect.
  #
  def test_target_detection


    a = []

    a.push('test.host.example.com must run ftp.')
    a.push('ftp://test.host.example.com/ must run ftp.')
    a.push('ftp://test.host.example.com/foo must run ftp.')
    a.push('test.host.example.com must run ping.')
    a.push("test.host.example.com  must run dns for bytemark.co.uk resolving NS as '80.68.80.26;85.17.170.78;80.68.80.27'.")
    a.push('rsync://test.host.example.com must run rsync.')
    a.push('rsync://test.host.example.com must run rsync.')

    a.each do |entry|
      assert_nothing_raised do
        obj = Custodian::TestFactory.create(entry)
        assert(obj)
        assert(obj.kind_of? Array)
        assert(!obj.empty?)
        assert_equal('test.host.example.com', obj[0].target)
      end
    end
  end

end
