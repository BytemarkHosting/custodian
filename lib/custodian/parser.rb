
require 'beanstalk-client'
require 'getoptlong'
require 'json'
require 'net/http'
require 'net/https'
require 'uri'








#
# This is a simple class which will parse a sentinel configuration file.
#
# Unlike Sentinel it is not built using a real parser, instead it peels off lines
# via a small number of very simple regular expressions - this should be flaky,
# but in practice it manages to successfully parse each of the configuration
# files that we currently maintain @ Bytemark.
#
# If there are any lines which are not recognized the class will raise an exception.
#
# Steve
# --
#
class MonitorConfig

  #
  # A hash of macros we found.
  #
  attr_reader :MACROS

  #
  # A handle to the beanstalkd queue.
  #
  attr_reader :queue

  #
  # The filename that we're going to parse.
  #
  attr_reader :filename

  #
  # Timeout period, in seconds, that we encode into test objects.
  #
  attr_reader :timeout



  #
  # Constructor
  #
  def initialize( filename )


    @MACROS  = Hash.new()
    @queue   = Beanstalk::Pool.new(['127.0.0.1:11300'])
    @file    = filename
    @timeout = 15

    raise ArgumentError, "Missing configuration file!" if ( @file.nil? )
    raise ArgumentError, "File not found: #{@file}" unless ( File.exists?( @file) )
  end


  #
  # Get the current value of the timeout figure.
  #
  def get_timeout()
    @timeout
  end


  #
  # Set the timeout value.
  #
  def set_timeout( new_val )
    @timeout = new_val
  end


  #
  # Retrieve a HTTP page from the web - this is used for macro-expansion
  #
  # NOTE:  This came from sentinel.
  #
  def getURL (uri_str)
    begin
      uri_str = 'http://' + uri_str unless uri_str.match(/^http/)
      url = URI.parse(uri_str)
      http = Net::HTTP.new(url.host, url.port)
      http.open_timeout = @timeout
      http.read_timeout = @timeout

      if (url.scheme == "https")
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end

      response = nil

      if nil == url.query
        response = http.start { http.get(url.path) }
      else
        response = http.start { http.get("#{url.path}?#{url.query}") }
      end


      if ( response.code.to_i != 200 )
        puts "Status code of #{uri_str} was #{response.code}"
        puts "ABORTING"
        exit( 0 )
      end

      case response
      when Net::HTTPRedirection
      then
        newURL = response['location'].match(/^http/)?
        response['Location']:uri_str+response['Location']
        return( getURL(newURL) )
      else
        return response.body
      end

    rescue Errno::EHOSTUNREACH => ex
      raise ex, "no route to host"
    rescue Timeout::Error => ex
      raise ex, "timeout"
    rescue Errno::ECONNREFUSED => ex
      raise ex, "connection refused"
    end
  end



  #
  #  Define a macro, from the configuration file.
  #
  def define_macro( line )
    name = nil
    val  = Array.new

    #
    #  Get the name of the macro.
    #
    name = $1.dup if ( line =~ /^([0-9A-Z_]+)\s+/ )


    #
    #  Get the value
    #
    if ( line =~ /fetched\s+from\s+(.*)[\r\n\.]*$/ )

      #
      #  HTTP-fetch
      #
      uri = $1.dup.chomp(".")

      text = getURL(uri)
      text.split( /[\r\n]/ ).each do |line|
        val.push( line ) if ( line.length() > 0)
      end

    elsif ( line =~ /\s(is|are)\s+(.*)\.+$/ )

      #
      #  Literal list of hosts
      #
      hosts = $2.dup

      #
      #  If there is " and " then tokenize
      #
      if ( hosts =~ /\s+and\s+/ )
        tmp = hosts.split( /\s+and\s+/ )
        tmp.each do |entry|
          val.push( entry )
        end
      else
        #
        # Otherwise a single host
        #
        val.push( hosts )
      end


    end

    if ( is_macro?( name ) )
      raise ArgumentError, "The macro #{name} is already defined"
    end

    @MACROS[name] = val
  end




  #
  #  Return a hash of our current macro-definitions.
  #
  #  This is used only by the test-suite.
  #
  def macros
    @MACROS
  end




  #
  # Is the given string of text a macro?
  #
  def is_macro?( name )
    !(@MACROS[name]).nil?
  end



  #
  # Return an array of hosts if the given string was a macro identifier.
  #
  def get_macro_targets( name )
    @MACROS[name]
  end




  #
  # Parse a single line from the configuration file.
  #
  def parse_line( line )

    line.chomp! if ( !line.nil? )

    #
    # A blank line, or a comment may be skipped.
    #
    return nil if ( ( line.nil? ) || ( line =~ /^#/ ) || ( line.length < 1 ) )

    #
    # The specification of mauve-server to which we should raise our alerts to.
    #
    return nil if ( line =~ /Mauve\s+server(.*)source/ )


    #
    #  Look for macro definitions, inline
    #
    if ( line =~ /^([0-9A-Z]_+)\s+are\s+fetched\s+from\s+([^\s]+)\.?/ )
      define_macro( line )

    elsif ( line =~ /^([0-9A-Z_]+)\s+(is|are)\s+/ )
      define_macro( line )

    elsif ( line =~ /(.*)\s+must\s+ping(.*)/ )

      #
      #  Ping is a special case because the configuration file entry
      # would read:
      #
      #  $FOO must ping otherwise ...
      #
      #  All other tests are of the form:
      #
      #  $FOO must run XXX ... otherwise ...
      #
      #  If we clevery rewrite the line into:
      #
      #  ... must run ping ...
      #
      #  We can avoid duplicating the macro-expansion, etc.
      #
      pre  = $1.dup
      post = $2.dup
      new_line = "#{pre} must run ping #{post}"
      return( parse_line( new_line ) )

    elsif ( line =~ /\s+must\s+run\s+([^\s]+)(\s+|\.|$)/i )

      #
      # Get the service we're testing, and remove any trailing "."
      #
      # This handles the case of:
      #
      #  LINN_HOSTS must run ssh.
      #
      service = $1.dup
      service.chomp!(".")

      #
      #  Target of the service-test.
      #
      targets = Array.new
      target  = line.split( /\s+/)[0]

      #
      #  If the target is a macro then get the list of hosts to
      # which the test will apply.
      #
      if ( is_macro?( target ) )
        targets = get_macro_targets( target )
      else

        #
        # Otherwise a list of one, literal, entry.
        #
        targets.push( target )
      end

      #
      # All our service tests, except ping, require a port - we setup the defaults here,
      # but the configuration file will allow users to specify an alternative
      # via " on XXX ".
      #
      case service
      when /ssh/ then
        port=22
      when /jabber/ then
        port=5222
      when /ldap/ then
        port=389
      when /^https$/ then
        port=443
      when /^http$/ then
        port=80
      when /rsync/i then
        port=873
      when /ftp/i then
        port=21
      when /telnet/i then
        port=23
      when /smtp/i then
        port=25
      when /dns/i then
        port=53
      end

      #
      # Allow the port to be changed, for example:
      #
      #  must run ssh  on   33 otherwise ..
      #  must run ftp  on   44 otherwise ..
      #  must run http on 8000 otherwise ..
      #
      if ( line =~ /\s+on\s+([0-9]+)/ )
        port = $1.dup
      end


      #
      # The array of JSON objects we will return to the caller.
      #
      ret = Array.new()

      #
      # For each host in our possibly-macro-expanded list:
      #
      targets.each do |host|

        #
        # The test we'll apply.
        #
        test = {
          :target_host => host,
          :test_type   => service,
          :test_port   => port,
          :verbose     => true,
          :timeout     => @timeout
        }

        #
        # Sanity check the hostname for ping-tests, to
        # avoid this security hole:
        #
        #   $(/tmp/exploit.sh) must run ping ..
        #
        if ( service == "ping" )
          raise ArgumentError, "Invalid hostname for ping-test: #{host}" unless( host =~ /^([a-zA-Z0-9:\-\.]+)$/ )
        end


        #
        #  Alert text will have a default, which may be overridden.
        #
        alert = "#{service} failed on #{host}"
        if ( line =~ /otherwise '([^']+)'/ )
          alert=$1.dup
        end

        #
        # Store the alert
        #
        # Note: We do this in the loop so that we can have "on $host" with
        # the per-test hostname inserted.
        #
        test[:test_alert] = alert

        #
        # TCP-tests will include a banner, optionally
        #
        if ( test[:test_type] =~ /tcp/ )
          if ( line =~ /\s+with\s+banner\s+'([^']+)'/ )
            test[:banner]=$1.dup
          else
            puts "You did not specify a banner to match against in line: #{line}"
          end
        end


        #
        # HTTP-tests will include the expected result in one of two forms:
        #
        #    must run http with status 200
        #
        #    must run http with content 'text'
        #
        # If those are sepcified then include them here.
        #
        # Note we're deliberately fast and loose here - which allows both to
        # be specified:
        #
        # http://example.vm/ must run http with status 200 and content 'OK'.
        #
        #
        if ( test[:test_type] =~ /^https?/ )
          found = 0

          if ( line =~ /\s+with\s+status\s+([0-9]+)\s+/ )
            test[:http_status]=$1.dup
            found += 1
          end
          if ( line =~ /\s+with\s+content\s+'([^']+)'/ )
            test[:http_text]=$1.dup
            found += 1
          end

          if ( found == 0 )
            puts "WARNING: Neither an expected text, or a status code, were specified in the line: #{line}"
          end
        end


        #
        # These are special cased for the DNS types
        #
        if ( test[:test_type] =~ /dns/ )

          #
          #  Sample line:
          #
          # DNSHOSTS must run dns for www.bytemark.co.uk resolving A as '212.110.161.144'.
          #
          #
          if ( line =~ /for\s+([^\s]+)\sresolving\s([A-Z]+)\s+as\s'([^']+)'/ )
            test[:resolve_name]     = $1.dup
            test[:resolve_type]     = $2.dup
            test[:resolve_expected] = $3.dup
          end
        end


        #
        #  Just testing syntax?  At this point we're done
        #
        next if ( ENV['TEST'] )

        #
        # We've now parsed the line.  Either output the JSON to the console
        # or add to the queue.
        #
        if ( !ENV['DUMP'].nil? )
          puts ( test.to_json )
        else
          @queue.put( test.to_json )
        end

        ret.push( test.to_json )
      end

      ret
    else
      raise ArgumentError, "Unknown line: '#{line}'"
    end
  end




  #
  # Parse the configuration file which was named in our constructor.
  #
  def parse_file()
    #
    #  Parse the configuration file on the command line
    #
    File.open( @file, "r").each_line do |line|
      parse_line( line)
    end
  end


end

