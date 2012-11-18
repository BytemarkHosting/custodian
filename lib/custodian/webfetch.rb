#!/usr/bin/ruby1.8


require 'tempfile'


#
# This is a class which allows a remote HTTP/HTTPS page to be downloaded
# it allows both the content and the HTTP status-code to be retrieved assuming
# a success was made.
#
# This code is *horrificly* bad, but required because net/http doesn't honour
# timouts under certain circumstances.  I'm not proud of this code.
#
# Steve
# -- 
#
class WebFetch

  #
  # The URL & timeout period (in seconds) we were given in the constructor
  #
  attr_reader :url, :timeout

  #
  # The HTTP status code, and content, we received from fetching the URL
  #
  attr_reader :status, :text

  #
  # An error to return to the caller, on failure
  #
  attr_reader :error



  #
  # Constructor
  #
  def initialize( url, timeout = 10 )
    @url     = url
    @timeout = timeout

    # defaults
    @status  = -1
    @error   = ""
    @text    = ""
  end



  #
  # Perform the fetch of the remote URL.  Return "true" on success.
  #
  def fetch

    #
    # Generate a temporary file to contain the header from the server.
    #
    tmp_head = Tempfile.new('curl-header')
    head     = tmp_head.path

    #
    # Generate a temporary file to contain the body from the server.
    #
    tmp_body = Tempfile.new('curl-body')
    body     = tmp_body.path

    #
    # Shell out to curl (!!!) to do the fetch.
    #
    system( "curl --max-time #{timeout} --silent --location --insecure --dump-header #{head} --out #{body} --silent #{@url}")


    #
    # If the header was empty then we're a failure.
    #
    # (A body might be legitimately empty.)
    #
    if ( File.size( head ) == 0 )

      #
      # Cleanup
      #
      File.unlink( body ) if ( File.exists?( body ) )
      File.unlink( head ) if ( File.exists?( head ) )

      #
      # Store the error.
      #
      @error = "Fetch of #{@url} failed"
      return false
    end


    #
    #  Get the HTTP status code, by parsing the HTTP headers.
    #
    #  NOTE: We will replace the code with later ones - this gives
    #  the status code *after* any potential redirection(s) have
    #  completed.
    #
    File.open( head, "r").each_line do |line|
      if ( line =~ /HTTP\/[0-9]\.[0-9]\s+([0-9]+)\s+/ )
        @status = $1.dup
      end
    end

    #
    #  Get the body from the server, by parsing the temporary file.
    #
    File.open( body, "r").each_line do |line|
      @text << line
    end

    #
    #  Cleanup.  We're done.
    #
    File.unlink( body ) if ( File.exists?( body ) )
    File.unlink( head ) if ( File.exists?( head ) )

    return true
  end


  #
  # Return the HTTP status code the server responded with, if the fetch was successful.
  #
  def status
    @status
  end

  #
  # Return the HTTP content the server responded with, if the fetch was successful.
  #
  def content
    @text
  end

  #
  # Return the error, if the fetch failed.
  #
  def error
    @error
  end

end

