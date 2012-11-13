#!/usr/bin/ruby1.8


require 'resolv-replace'


#
#  This is a protocol tester for DNS.
#
class DNSTest

  #
  # Data passed from the JSON hash.
  #
  attr_reader :test_data

  #
  # The error text we return on failure.
  #
  attr_reader :error



  #
  # Save the data away.
  #
  def initialize( data )
    @test_data = data
    @error     = nil

    #
    # Ensure we have a host to monitor
    #
    if ( @test_data["target_host"].nil? )
      @error = "Missing host to test against."
      raise ArgumentError, @error
    end

    #
    #  Ensure we have test-specific keys.
    #
    if ( @test_data["resolve_name"].nil? )
      @error = "Missing host to resolve."
      raise ArgumentError, @error
    end
    if ( @test_data["resolve_type"].nil? )
      @error = "Missing type to resolve, for example A/MX/NS."
      raise ArgumentError, @error
    end
    if ( @test_data["resolve_expected"].nil? )
      @error = "Missing expected results to compare against.."
      raise ArgumentError, @error
    end
  end


  #
  # Run the test.
  #
  #  Return "true" on success
  #
  #  Return "false" on failure.
  #
  # If the test fails the details should be retrieved from "error()".
  #
  def run_test

    #
    # Get the nameserver to resolve with
    #
    nameserver = @test_data["target_host"]

    #
    # Get the record type to lookup
    #
    record = @test_data["resolve_type"]

    #
    # Get the hostname to lookup
    #
    lookup = @test_data["resolve_name"]

    #
    # Get the expected results
    #
    expected = @test_data["resolve_expected"]

    #
    # Do the lookup
    #
    results = resolve_via( nameserver, record, lookup )

    #
    # Show the results if we found something.
    #
    if ( @test_data['verbose'] )
      results.each do |res|
        puts "Result: #{res}"
      end
    end

    #
    # OK we have an array of results.  If every one of the expected
    # results is contained in those results returned then we're good.
    #
    expected.split( /;/ ).each do |required|
      if ( ! results.include?( required ) )
        @error = "The expected result #{required} was not found in the results: #{results.join(",")}"
        return false
      end
    end

    return true
  end


  #
  # Resolve an IP
  #
  def resolve_via( server, ltype, name )
    puts "Resolving #{name} [#{ltype}] via server #{server}"

    results = Array.new()

    Resolv::DNS.open(:nameserver=>[server]) do |dns|
      case ltype
      when /^A$/ then
        dns.getresources(name, Resolv::DNS::Resource::IN::A).map{ |r| results.push r.address.to_s() }
      when /^AAAA$/ then
        dns.getresources(name, Resolv::DNS::Resource::IN::AAAA).map{ |r| results.push r.address.to_s() }

      when /^NS$/ then
        dns.getresources(name, Resolv::DNS::Resource::IN::MX).map{ |r| results.pushResolv.getaddresses(r.name.to_s()) }

      when /^MX$/ then
        dns.getresources(name, Resolv::DNS::Resource::IN::MX).map{ |r| results.push Resolv.getaddresses(r.exchange.to_s()) }
      end
    end

    results.flatten!
    return results
  end


  #
  #  Return the error text for why this test failed.
  #
  def error
    return @error
  end




end



#
# Sample test, for testing.
#
if __FILE__ == $0 then

  #
  #  Sample data.
  #
  test = {
    "target_host"      => "a.ns.bytemark.co.uk",
    "test_type"        => "dns",
    "verbose"          => 1,
    "test_alert"       => "DNS failure",
    "resolve_name"     => "support.bytemark.co.uk",
    "resolve_type"     => "MX",
    "resolve_expected" => "89.16.184.148;89.16.184.149;89.16.184.150"
  }


  #
  #  Run the test.
  #
  obj = DNSTest.new( test )
  if ( obj.run_test )
    puts "TEST OK"
  else
    puts "TEST FAILED"
    puts obj.error()
  end

end
