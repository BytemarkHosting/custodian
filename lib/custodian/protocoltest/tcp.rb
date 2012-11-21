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
  # Constructor
  #
  # Ensure we received a port to run the TCP-test against.
  #
  def initialize( line )
    raise ArgumentError, "Missing port" unless ( line =~ /on\s+([0-9]+)/ );
    @error = nil
  end


  #
  # Helper for development.
  #
  def display
    puts "I'm a TCP-test!"
  end


  #
  # Run the TCP-protocol test.
  #
  def run_test

    # reset the error, in case we were previously executed.
    @error = nil

  end


  #
  # If the test fails then report the error.
  #
  def error
    @error
  end

  register_test_type "tcp"

end
