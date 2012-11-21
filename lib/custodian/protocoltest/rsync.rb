#
#  The RSYNC-protocol test.
#
#  This object is instantiated if the parser sees a line such as:
#
###
### upload.ns.bytemark.co.uk must run rsync otherwise 'dns upload failure'.
###
#
#  The specification of the port is optional and defaults to 873
#
class RSYNCTest < TCPTest


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
      @port = 873
    end
  end




  #
  # Helper for development.
  #
  def to_s
    "rsync-test of #{@host}:#{@port}."
  end




  #
  # Convert this class to JSON such that it may be serialized.
  #
  def to_json
    hash = {
            :test_type   => 'rsync',
            :test_target => @host,
            :test_port   => @port,
    }
    hash.to_json
  end




  #
  # Run the protocol test.
  #
  def run_test

    # reset the error, in case we were previously executed.
    @error = nil

    run_test_internal( @host, @port, "@RSYNCD" )
  end




  #
  # If the test fails then report the error.
  #
  def error
    @error
  end




  register_test_type "rsync"




end
