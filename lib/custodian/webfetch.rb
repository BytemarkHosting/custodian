#!/usr/bin/ruby1.8


require 'tempfile'


class WebFetch

  #
  # The URL & timeout period (in seconds) we were given in the constructor
  #
  attr_reader :url, :timeout

  #
  # The HTTP status code, and content, we received from fetching the URL
  #
  attr_reader :status, :text, :error



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
  # Perform the fetch.
  #
  # Return true on success.
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
    # If both files are size zero then we clearly failed.
    #
    if ( ( File.size( body ) == 0 ) ||
         ( File.size( head ) == 0 ) )

      #
      # Cleanup
      #
      File.unlink( body ) if ( File.exists?( body ) )
      File.unlink( head ) if ( File.exists?( head ) )

      #
      # Save the error.
      #
      @error = "Fetch failed"
      return false
    end


    #
    #  Get the HTTP status code, by parsing the HTTP headers.
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
  # Return the HTTP status code the server responded with, if the
  # fetch was successful.
  #
  def status
    @status
  end

  #
  # Return the HTTP content the server responded with, if the
  # fetch was successful.
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

