#!/usr/bin/ruby1.8 -I./lib/ -I../lib/


require 'json'
require 'test/unit'
require 'custodian/parser'




#
# Unit test for our parser.
#
class TestParser < Test::Unit::TestCase

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
  #  Test we can create a new parser object - specifically
  # that it throws exceptions if it is not given a filename
  # that exists.
  #
  def test_init

    #
    #  Missing filename -> Exception
    #
    assert_raise ArgumentError do
      MonitorConfig.new()
    end

    #
    #  Filename points to file that doesn't exist -> Exception
    #
    assert_raise ArgumentError do
      MonitorConfig.new("/file/doesn't/exist")
    end

    #
    #  File that exists -> No Exception.
    #
    assert_nothing_raised do
      MonitorConfig.new("/dev/null" )
    end

  end


  #
  #  Test that we can define macros.
  #
  def test_macros

    parser = MonitorConfig.new("/dev/null" )

    #
    #  With nothing loaded we should have zero macros - so the
    # count of our macros hash should be zero
    #
    macros = parser.macros
    assert( macros.empty? )
    assert( macros.size() == 0 )


    #
    #  Define a macro:
    #
    #  FOO =>  "kvm1.vm.bytemark.co.uk", "kvm2.vm.bytemark.co.uk".
    #
    #  Before defining it double-check it doesn't exist
    #
    assert( !(parser.is_macro?( "FOO" )) )

    #
    #  Add it.
    #
    ret = parser.define_macro( "FOO is kvm1.vm.bytemark.co.uk and kvm2.vm.bytemark.co.uk." )

    #
    #  The return value should be an array containing the values we added.
    #
    assert( ret.class.to_s == "Array" )
    assert( ret.size == 2 )
    assert( ret.include?( "kvm1.vm.bytemark.co.uk" ) )
    assert( ret.include?( "kvm2.vm.bytemark.co.uk" ) )


    #
    #  OK we should now have a single macro defined.
    #
    macros = parser.macros
    assert( macros.size() == 1 )


    #
    #  The macro name "FOO" should exist
    #
    assert( parser.is_macro?( "FOO" ) )

    #
    #  The contents of the FOO macro should have the value we expect
    #
    val = parser.get_macro_targets( "FOO" )
    assert( val.size() == 2 )
    assert( val.include?( "kvm1.vm.bytemark.co.uk" ) )
    assert( val.include?( "kvm2.vm.bytemark.co.uk" ) )


    #
    # Add a macro, using the parser directly.
    #
    # Before defining it double-check it doesn't exist
    #
    assert( !(parser.is_macro?( "BAR" )) )

    #
    # Add it.
    #
    ret = parser.parse_line( "BAR is example.vm.bytemark.co.uk and www.bytemark.co.uk." )

    #
    #  The return value should be an array containing the values
    # we added.
    #
    assert( ret.class.to_s == "Array" )
    assert( ret.size == 2 )
    assert( ret.include?( "example.vm.bytemark.co.uk" ) )
    assert( ret.include?( "www.bytemark.co.uk" ) )


    #
    #  OK we should now have two macros defined.
    #
    macros = parser.macros
    assert( macros.size() == 2 )

    #
    #  The macro name "BAR" should exist
    #
    assert( parser.is_macro?( "BAR" ) )

    #
    #  The contents of the BAR macro should have the value we expect
    #
    val = parser.get_macro_targets( "BAR" )
    assert( val.size() == 2 )
    assert( val.include?( "example.vm.bytemark.co.uk" ) )
    assert( val.include?( "www.bytemark.co.uk" ) )
  end




  #
  #  Test that we can define macros with only a single host.
  #
  def test_short_macros

    parser = MonitorConfig.new("/dev/null" )

    #
    #  With nothing loaded we should have zero macros - so the
    # count of our macros hash should be zero
    #
    macros = parser.macros
    assert( macros.empty? )
    assert( macros.size() == 0 )


    #
    #  Define a macro:
    #
    #  FOO =>  "kvm1.vm.bytemark.co.uk".
    #
    #  Before defining it double-check it doesn't exist
    #
    assert( !(parser.is_macro?( "FOO" )) )

    #
    #  Add it.
    #
    ret = parser.define_macro( "FOO is kvm1.vm.bytemark.co.uk." )

    #
    #  The return value should be an array containing the values we added.
    #
    assert( ret.class.to_s == "Array" )
    assert( ret.size == 1 )
    assert( ret.include?( "kvm1.vm.bytemark.co.uk" ) )


    #
    #  OK we should now have a single macro defined.
    #
    macros = parser.macros
    assert( macros.size() == 1 )

    #
    # Add a macro, using the parser directly.
    #
    # Before defining it double-check it doesn't exist
    #
    assert( !(parser.is_macro?( "BAR_HOSTS" )) )

    #
    # Add it.
    #
    ret = parser.parse_line( "BAR_HOSTS are example.vm.bytemark.co.uk." )

    #
    #  The return value should be an array containing the single value
    # we added.
    #
    assert( ret.class.to_s == "Array" )
    assert( ret.size == 1 )
    assert( ret.include?( "example.vm.bytemark.co.uk" ) )

    #
    #  OK we should now have two macros defined.
    #
    macros = parser.macros
    assert( macros.size() == 2 )

    #
    #  The macro name "BAR_HOSTS" should exist
    #
    assert( parser.is_macro?( "BAR_HOSTS" ) )

    #
    #  The contents of the BAR macro should have the single value we expect.
    #
    val = parser.get_macro_targets( "BAR_HOSTS" )
    assert( val.size() == 1 )
    assert( val.include?( "example.vm.bytemark.co.uk" ) )
  end


  def test_misc_macro

    parser = MonitorConfig.new("/dev/null" )

    #
    #  With nothing loaded we should have zero macros - so the
    # count of our macros hash should be zero
    #
    macros = parser.macros
    assert( macros.empty? )
    assert( macros.size() == 0 )

    parser.parse_line( "FRONTLINESTAGING2 is 89.16.186.138 and 89.16.186.139 and 89.16.186.148." )

    macros = parser.macros
    assert( macros.size() == 1 )

    #
    # Test that we got a suitable value.
    #
    values = parser.get_macro_targets( "FRONTLINESTAGING2" )
    assert(values.class.to_s == "Array" )


    #
    # Parse another line
    #
    parser.parse_line( "SWML_HOSTS is 212.110.191.9.")
    macros = parser.macros
    assert( macros.size() == 2 )
    values = parser.get_macro_targets( "SWML_HOSTS" )
    assert(values.class.to_s == "Array" )



  end



  #
  #  Test that we can define tests which expand macros successfully.
  #
  def test_adding_tests

    parser = MonitorConfig.new("/dev/null" )

    #
    # Adding a test should return an array - an array of JSON strings.
    #
    ret = parser.parse_line( "example.vm.bytemark must run ssh otherwise 'I hate you'." )
    assert_equal( ret.class.to_s, "Array" )
    assert_equal( ret.size(), 1 )

    #
    # Define a macro - such that a single added test will become
    # several indivual tests.
    #
    parser.parse_line( "MACRO is kvm1.vm.bytemark.co.uk and kvm1.vm.bytemark.co.uk and kvm3.vm.bytemark.co.uk." )
    assert( parser.is_macro?( "MACRO") )

    #
    # Now add a ping-test against that macro
    #
    ret = parser.parse_line( "MACRO must run ping otherwise 'ping failure'." )

    #
    # The resulting array should contain three JSON strings.
    #
    assert_equal( ret.class.to_s, "Array" )
    assert_equal( ret.size(),3 )

    #
    # Ensure we look like valid JSON, and contains the correct hostnames.
    #
    ret.each do |test|
      assert( test =~ /^\{/ )
      assert( test =~ /(kvm1|kvm2|kvm3)\.vm.bytemark.co.uk/ )
    end

    #
    #  Now add more alerts, and ensure we find something sane:
    #
    #   1.  The addition should be JSON.
    #
    #   2.  The addition should have the correct test-type
    #
    %w( dns ftp http https jabber ldap ping rsync ssh smtp ).each do |name|
      ret = parser.parse_line( "MACRO must run #{name} otherwise '#{name} failure'." )

      #
      # The resulting array should contain three JSON strings.
      #
      assert_equal( ret.class.to_s, "Array" )
      assert_equal( ret.size(),3 )

      #
      #  The test-type should be set to the correct test.
      #
      ret.each do |test|

        #
        #  Look for valid-seeming JSON with a string match
        #
        assert( test =~ /^\{/ )
        assert( test =~ /"test_type":"#{name}"/ )

        #
        #  Deserialize and look for a literal match
        #
        hash = JSON.parse( test )
        assert( hash['test_type'] == name )

      end
    end
  end



  #
  # Most services define a default port.  Ensure that is correct.
  #
  def test_default_ports

    expected = {
      "dns" => 53,
      "ftp" => 21,
      "ldap" => 389,
      "jabber" => 5222,
      "http" => 80,
      "rsync" => 873,
      "smtp" => 25,
      "ssh" => 22,
    }


    #
    #  Create the helper
    #
    parser = MonitorConfig.new("/dev/null" )


    #
    #  Run through our cases
    #
    expected.each do |test,port|

      #
      # Adding a test should return an array - an array of JSON strings.
      #
      ret = parser.parse_line( "example.vm.bytemark must run #{test} otherwise 'fail'." )
      assert_equal( ret.class.to_s, "Array" )
      assert_equal( ret.size(), 1 )

      #
      # Get the (sole) member of the array
      #
      addition = ret[0]

      #
      # Look for the correct port in our JSON.
      #
      assert( addition =~ /"test_port":#{port}/ )

      #
      # Deserialize and look for a literal match.
      #
      hash = JSON.parse( addition )
      assert( hash['test_port'] == port )
    end
  end


  #
  # Comment-handling
  #
  def test_adding_comments

    parser = MonitorConfig.new("/dev/null" )

    #
    # Adding comments should result in a nil return value.
    #
    assert( parser.parse_line( "# This is a comment" ).nil? )
    assert( parser.parse_line( "\n" ).nil? )
    assert( parser.parse_line( "" ).nil? )
    assert( parser.parse_line( nil ).nil? )
  end


end
