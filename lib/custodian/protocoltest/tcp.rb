require 'socket'
require 'timeout'


#
#  The TCP-protocol test.
#
#  This object is instantiated if the parser sees a line such as:
#
###
### foo.vm.bytemark.co.uk must run tcp on 22 with banner 'ssh' otherwise 'ssh fail'.
###
#
#  The specification of the port is mandatory, the banner is optional.
#
class TCPTest < ProtocolTest


  #
  # The host to test against.
  #
  attr_reader :host


  #
  # The port to connect to.
  #
  attr_reader :port


  #
  #  The banner to look for, may be nil.
  #
  attr_reader :banner




  #
  # Constructor
  #
  # Ensure we received a port to run the TCP-test against.
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
      @port = nil
    end

    #
    # Save the optional banner.
    #
    if ( line =~ /with\s+banner\s+'([^']+)'/ )
      @banner = $1.dup
    else
      @banner = nil
    end

    @error = nil

    if ( @port.nil? )
      raise ArgumentError, "Missing port to test against"
    end
  end




  #
  # Helper for development.
  #
  def to_s
    "tcp-test of #{@host}:#{@port} looking for banner '#{@banner}'."
  end




  #
  # Convert this class to JSON such that it may be serialized.
  #
  def to_json
    hash = {
            :test_type   => 'tcp',
            :test_target => @host,
            :test_port   => @port,
            :banner      => @banner
    }
    hash.to_json
  end




  #
  # Run the TCP-protocol test.
  #
  def run_test

    # reset the error, in case we were previously executed.
    @error = nil

    return( run_test_internal( @host, @port, @banner ) )
  end




  #
  # Run the connection test - optionally matching against the banner.
  #
  # If the banner is nil then we're merely testing we can connect and
  # send the string "quit".
  #
  #
  def run_test_internal( host, port, banner = nil )
    begin
      timeout(30) do
        begin
          socket = TCPSocket.new( host, port )
          socket.puts( "QUIT")

          # read a banner from the remote server
          read = socket.gets(nil)

          # trim to a sane length & strip newlines.
          read = read[0,255] unless ( read.nil? )
          read.gsub!(/[\n\r]/, "") unless ( read.nil? )

          socket.close()

          if ( banner.nil? )
            @error = nil
            return true
          else
            # test for banner
            if ( ( !read.nil? ) && ( read =~ /#{banner}/i ) )
              return true
            end

            @error = "We expected a banner matching '#{banner}' but we got '#{read}'"
            return false
          end
        rescue
          @error = "Exception connecting to host #{host}:#{port} - #{$!}"
          return false
        end
      end
    rescue Timeout::Error => e
      @error = "TIMEOUT: #{e}"
      return false
    end
    @error = "Misc failure"
    return false
  end




  #
  # If the test fails then report the error.
  #
  def error
    @error
  end




  register_test_type "tcp"




end
