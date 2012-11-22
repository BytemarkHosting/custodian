
#
#  The HTTP-protocol test.
#
#  This object is instantiated if the parser sees a line such as:
#
###
### http://foo.vm.bytemark.co.uk/ must run http with content 'foo' otherwise 'ftp fail'.
###
#
#
class HTTPTest < TCPTest


  #
  # The line from which we were constructed.
  #
  attr_reader :line


  #
  # The URL to poll
  #
  attr_reader :url

  #
  # Constructor
  #
  def initialize( line )

    #
    #  Save the line
    #
    @line = line

    #
    #  Save the URL
    #
    @url  = line.split( /\s+/)[0]


    if ( @url !~ /^https?:/ )
      raise ArgumentError, "The target wasn't an URL"
    end

  end




  #
  # Helper for development.
  #
  def to_s
    "http-test of #{@url}."
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
    @error = "Not implemented"
    false
  end




  #
  # If the test fails then report the error.
  #
  def error
    @error
  end




  register_test_type "http"
  register_test_type "https"




end
