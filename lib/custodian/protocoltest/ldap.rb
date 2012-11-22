require 'custodian/protocoltest/tcp'


#
#  The LDAP-protocol test.
#
#  This object is instantiated if the parser sees a line such as:
#
###
### foo.vm.bytemark.co.uk must run ldap otherwise 'auth-server fail'.
###
#
#  The specification of the port is optional and defaults to 389.
#
class LDAPTest < TCPTest


  #
  # The line from which we were constructed.
  #
  attr_reader :line


  #
  # The host to test against.
  #
  attr_reader :host


  #
  # The port to connect to.
  #
  attr_reader :port




  #
  # Constructor
  #
  def initialize( line )

    #
    # Save the line.
    #
    @line = line

    #
    # Save the host
    #
    @host  = line.split( /\s+/)[0]

    #
    # Save the port
    #
    if ( line =~ /on\s+([0-9]+)/ )
      @port = $1.dup
    else
      @port = 389
    end
  end




  #
  # Helper for development.
  #
  def to_s
    "ldap-test of #{@host}:#{@port}."
  end




  #
  # Convert this class to JSON such that it may be serialized.
  #
  def to_json
    hash = { :line => @line }
    hash.to_json
  end




  #
  # Run the TCP-protocol test.
  #
  def run_test

    # reset the error, in case we were previously executed.
    @error = nil

    run_test_internal( @host, @port, nil, false )
  end




  #
  # If the test fails then report the error.
  #
  def error
    @error
  end




  register_test_type "ldap"




end
