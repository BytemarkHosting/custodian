#!/usr/bin/ruby
#
# Notes
#
#  Macros may be defined either literally, or as a result of a HTTP-fetch.
# Macro names match the pattern "^[0-9A-Z_]$"
#
#


require 'beanstalk-client'
require 'getoptlong'
require 'json'








#
# This is a simple class which will parse a sentinel configuration file.
#
# Unlike Sentinel it is not using a real parser, instead it peels off lines
# via a small number of very simple regular expressions - this should be flaky,
# but in practice it manages to successfully parse each of the configuration
# files that we currently maintain @ Bytemark.
#
# TODO:
#
# 1.  Explicitly abort and panic on malformed lines.
#
# 2.  Implement HTTP-fetching for macro-bodies.
#
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
  # Constructor
  #
  def initialize( filename )
    @MACROS = Hash.new()
    @queue  = Beanstalk::Pool.new(['127.0.0.1:11300'])
    @file   = filename

    if ( @file.nil? || ( ! File.exists?( @file) ) )
      raise ArgumentError, "Missing configuration file!"
    end
  end



  #
  #  Define a macro, from the configuration file.
  #
  def define_macro( line )
    name = nil
    val  = Array.new

    #
    #  Get the name
    #
    name = $1.dup if ( line =~ /^([A-Z_]+)\s+/ )


    #
    #  Get the value
    #
    if ( line =~ /fetched\s+from\s+(.*)[\r\n\.]*$/ )

      #
      #  HTTP-fetch
      #
      val.push( "steve")
      val.push("kemp")

    elsif ( line =~ /\s(is|are)\s+(.*)\.+$/ )

      #
      #  Literal list.
      #
      tmp = $2.dup.split( /\s+and\s+/ )
      tmp.each do |entry|
        val.push( entry )
      end

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
    !@MACROS[name].nil?
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

    #
    # A blank line, or a comment may be skipped.
    #
    return if ( ( line =~ /^#/ ) || ( line.length < 1 ) )

    #
    # The specification of mauve-server to which we should raise our alerts to.
    #
    return if ( line =~ /Mauve\s+server(.*)source/ )


    #
    #  Look for macro definitions, inline
    #
    if ( line =~ /^([A-Z]_+)\s+are\s+fetched\s+from\s+([^\s]+)\.?/ )
      define_macro( line )

    elsif ( line =~ /^([0-9A-Z_]+)\s+(is|are)\s+/ )
      define_macro( line )

    elsif ( line =~ /\s+must\s+ping/ )

      #
      #  Target
      #
      targets = Array.new

      #
      #  Fallback target is the first token on the line
      #
      target = line.split( /\s+/)[0]


      #
      #  If the target is a macro
      #
      if ( is_macro?( target ) )
        targets = get_macro_targets(target)
      else
        targets.push( target )
      end

      #
      #  The alert-failure message
      #
      alert = "Ping failed"
      if ( line =~ /otherwise '([^']+)'/ )
        alert=$1.dup
      end

      #
      #  Store the test(s)
      #
      targets.each do |host|
        test = {
          :target_host => host,
          :test_type => "ping",
          :test_alert => alert
        }

        if ( !ENV['DUMP'].nil? )
          puts ( test.to_json )
        else
          @queue.put( test.to_json )
        end
      end

    elsif ( line =~ /\s+must\s+run\s+([^\s]+)\s+/i )

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
      #  If the target is a macro
      #
      if ( is_macro?( target ) )
        targets = get_macro_targets( target )
      else
        targets.push( target )
      end

      #
      #  Alert text
      #
      alert = "#{service} failed"
      if ( line =~ /otherwise '([^']+)'/ )
        alert=$1.dup
      end

      #
      # All our service tests require a port - we setup the defaults here,
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
      end

      #
      # But allow that to be changed
      #
      # e.g.
      #
      #  must run ssh on 33 otherwise ..
      #  must run ftp on 44 otherwise ..
      #  must run http on 8000 otherwise ..
      #
      if ( line =~ /\s+on\s+([0-9]+)/ )
        port = $1.dup
      end

      targets.each do |host|

        test = {
          :target_host => host,
          :test_type   => service,
          :test_port   => port,
          :test_alert  => alert
        }

        #
        # HTTP-tests will include the expected result in one of two
        # forms:
        #
        #    must run http with status 200
        #
        #    must run http with content 'text'
        #
        # If those are sepcified then include them here.
        #
        # Note we're deliberately fast and loose here - which allows both to be specified
        #
        #   http://example.vm/ must run http with status 200 and content 'OK' otherwise 'boo!'.
        #
        #
        if ( line =~ /\s+with\s+status\s+([0-9]+)\s+/ )
          test[:http_status]=$1.dup
        end
        if ( line =~ /\s+with\s+content\s+'([^']+)'/ )
          test[:http_text]=$1.dup
        end

        #
        # We've parsed(!) the line.  Either output the JSON to the console
        # or add to the queue.
        #
        if ( !ENV['DUMP'].nil? )
          puts ( test.to_json )
        else
          @queue.put( test.to_json )
        end
      end
    else
      puts "Unknown line: #{line}" if ( line.length > 2 )
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





#
#  Entry-point to our code.
#
if __FILE__ == $0 then


  begin
    opts = GetoptLong.new(
                          [ "--dump", "-d", GetoptLong::NO_ARGUMENT ],
                          [ "--file", "-f", GetoptLong::REQUIRED_ARGUMENT ]
                          )
    opts.each do |opt, arg|
      case opt
      when "--dump":
          ENV["DUMP"] = "1"
      when "--file":
          ENV["FILE"] = arg
      end
    end
  rescue StandardError => ex
    puts "Option parsing failed: #{ex.to_s}"
    exit
  end

  mon = MonitorConfig.new( ENV['FILE'] )
  mon.parse_file();
end
