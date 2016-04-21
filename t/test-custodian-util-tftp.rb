#!/usr/bin/ruby -I./lib/ -I../lib/

require 'custodian/util/tftp'
require 'test/unit'

#
# Unit test for our tftp utility class.
#
class TestTftpUtil < Test::Unit::TestCase


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
  # Test we can construct new objects.
  #
  def test_init

    #
    # Normal construction works.
    #
    assert_nothing_raised do
        Custodian::Util::Tftp.new('foo')
    end
    assert_nothing_raised do
        Custodian::Util::Tftp.new('foo', 123)
    end
    assert_nothing_raised do
        Custodian::Util::Tftp.new('foo', '123')
    end


    #
    # A hostname must be supplied
    #
    assert_raise ArgumentError do
        Custodian::Util::Tftp.new(nil)
    end

    #
    # A hostname is a string, not an array, hash, or similar.
    #
    assert_raise ArgumentError do
      Custodian::Util::Tftp.new({})
    end
    assert_raise ArgumentError do
      Custodian::Util::Tftp.new([])
    end

    #
    # A port, if supplied, must be a number
    #
    assert_raise ArgumentError do
      Custodian::Util::Tftp.new('foo', 'bar')
    end

    #
    # The default port is 69
    #
    assert_equal(Custodian::Util::Tftp.new('foo').port, 69)


  end

  #
  # Test a tftp successful fetch
  #
  def test_tftp_suceeds
    helper = Custodian::Util::Tftp.new('foo')
    def helper.tftp(args)
      filename = args.split(' ').last
      File.open(filename, 'w') { |w| w.puts 'stuff' }
      return true
    end

    assert(helper.test('file'))
  end

  #
  # Test a tftp failed fetch
  #
  def test_tftp_failed_fetch
    helper = Custodian::Util::Tftp.new('foo')
    def helper.tftp(args)
      return false
    end

    assert(!helper.test('file'))
  end

  #
  # Test a tftp fetch of empty file
  #
  def test_tftp_empty_file
    helper = Custodian::Util::Tftp.new('foo')
    def helper.tftp(args)
      filename = args.split(' ').last
      File.open(filename, 'w') { |w| }
      return true
    end

    assert(!helper.test('file'))
  end

end
