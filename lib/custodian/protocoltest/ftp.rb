#
#  The FTP-protocol test.
#
#  This object is instantiated if the parser sees a line such as:
#
###
### foo.vm.bytemark.co.uk must run ftp on 22 otherwise 'ftp fail'.
###
#
#  The specification of the port is optional and defaults to 21
#
class FTPTest < TCPTest


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
    # Save the host
    #
    @host  = line.split( /\s+/)[0]

    #
    # Save the port
    #
    if ( line =~ /on\s+([0-9]+)/ )
      @port = $1.dup
    else
      @port = 21
    end
  end




  #
  # Helper for development.
  #
  def to_s
    "ftp-test of #{@host}:#{@port}."
  end




  #
  # Run the TCP-protocol test.
  #
  def run_test

    # reset the error, in case we were previously executed.
    @error = nil

    run_test_internal( @host, @port, "^220" )
  end




  #
  # If the test fails then report the error.
  #
  def error
    @error
  end




  register_test_type "ftp"




end
