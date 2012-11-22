require 'custodian/testfactory.rb'


#
#  The ping test.
#
#  This object is instantiated if the parser sees a line such as:
#
###
### DNSHOSTS must run ping otherwise ..
###
#
#
class PINGTest < TestFactory


  #
  # The line from which we were constructed.
  #
  attr_reader :line


  #
  # The host to test against.
  #
  attr_reader :host




  #
  # Constructor
  #
  def initialize( line )

    #
    #  Save the line
    #
    @line = line

    #
    # Save the host
    #
    @host  = line.split( /\s+/)[0]
  end




  #
  # Helper for development.
  #
  def to_s
    "ping-test - #{@host}."
  end




  #
  # Convert this class to JSON such that it may be serialized.
  #
  def to_json
    hash = { :line => @line }
    hash.to_json
  end



  #
  # Run the test.
  #
  def run_test

    #
    # Find the binary we're going to invoke.
    #
    binary = nil
    binary = "/usr/bin/multi-ping"  if ( File.exists?( "/usr/bin/multi-ping" ) )

    if ( binary.nil? )
      @error = "Failed to find '/usr/bin/multi-ping'"
      return false
    end


    #
    # Sanity check the hostname for ping-tests, to
    # avoid this security hole:
    #
    #   $(/tmp/exploit.sh) must run ping ..
    #
    if ( @host !~ /^([a-zA-Z0-9:\-\.]+)$/ )
      @error = "Invalid hostname for ping-test: #{@host}"
      return false
    end


    #
    # Run the test.
    #
    if ( system( "#{binary} #{host}" ) == true )
      return true
    else
      @error = "Ping failed."
      return false
    end

  end




  #
  # If the test fails then report the error.
  #
  def error
    @error
  end




  register_test_type "ping"




end
