
require 'net/http'
require 'net/https'
require 'uri'


#
# The modules we've implemented
#
require 'custodian/protocoltests'
require 'custodian/util/timespan'





#
# This is a simple class which will parse a configuration file.
#
# The class peels off lines via a small number of very simple regular
# expressions - this should be flaky,  but in practice it manages to
# successfully parse each of the configuration files that we currently
# maintain @ Bytemark.
#
# If there are any lines which are not recognized the class will raise an exception.
#
#
# Steve
# --
#
module Custodian

  class Parser

    #
    # A hash of macros we found.
    #
    attr_reader :MACROS

    #
    # The filename that we're going to parse.
    #
    attr_reader :filename

    #
    # An array of test-objects, which are subclasses of our test-factory.
    #
    attr_reader :jobs



    #
    # Constructor
    #
    def initialize
      @MACROS  = {}
      @jobs    = []
    end




    #
    # Retrieve a HTTP/HTTPS page from the web, for macro-expansion.
    #
    def get_url_contents(uri_str)
      begin
        uri_str = 'http://' + uri_str unless uri_str.match(/^http/)
        url = URI.parse(uri_str)
        http = Net::HTTP.new(url.host, url.port)

        # timeout for the HTTP-fetch, in seconds.
        http.open_timeout = 60
        http.read_timeout = 60

        if (url.scheme == 'https')
          http.use_ssl = true
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end

        response = nil

        if nil == url.query
          response = http.start { http.get(url.path) }
        else
          response = http.start { http.get("#{url.path}?#{url.query}") }
        end


        if (response.code.to_i != 200)
          puts "Status code of #{uri_str} was #{response.code}"
          puts 'ABORTING'
          exit(0)
        end

        case response
        when Net::HTTPRedirection
        then
          newURL = response['location'].match(/^http/) ?           response['Location'] : uri_str + response['Location']
          return(get_url_contents(newURL))
        else
          return response.body
        end

      rescue Errno::EHOSTUNREACH => ex
        raise ex, 'no route to host'
      rescue Timeout::Error => ex
        raise ex, 'timeout'
      rescue Errno::ECONNREFUSED => ex
        raise ex, 'connection refused'
      end
    end



    #
    #  Define a macro, from the configuration file.
    #
    def define_macro(line)
      name = nil
      val  = []

      #
      #  Get the name of the macro.
      #
      name = $1.dup if  line =~ /^([0-9A-Z_]+)\s+/


      #
      #  Get the value
      #
      if  line =~ /fetched\s+from\s+(.*)[\r\n\.]*$/

        #
        #  HTTP-fetch
        #
        uri = $1.dup.chomp('.')

        text = get_url_contents(uri)
        text.split(/[\r\n]/).each do |line|
          val.push(line) if  line.length > 0
        end

      elsif  line =~ /\s(is|are)\s+(.*)\.*$/

        #
        #  Literal list of hosts
        #
        hosts = $2.dup

        #
        #  If there is " and " then tokenize
        #
        if  hosts =~ /\s+and\s+/
          tmp = hosts.split(/\s+and\s+/)
          tmp.each do |entry|
            val.push(entry)
          end
        else
          #
          # Otherwise a single host
          #
          val.push(hosts)
        end
      end

      if  is_macro?(name)
        raise ArgumentError, "The macro #{name} is already defined"
      end

      @MACROS[name] = val

      true
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
    def is_macro?(name)
      !(@MACROS[name]).nil?
    end



    #
    # Return an array of hosts if the given string was a macro identifier.
    #
    def get_macro_targets(name)
      @MACROS[name]
    end



    #
    #  Return multiple copies of a line for each macro-target
    #
    def expand_macro(input)

      r = []

      if  input =~ /^(\S+)\s+(.*)$/
        macro = $1.dup
        rest = $2.dup
      end


      if  is_macro?(macro)
        get_macro_targets(macro).each do |host|
          r.push("#{host} #{rest}")
        end
      else
        r.push(input)
      end

      r
    end


    #
    # Parse a single line from the configuration file.
    #
    def parse_line(line)

      raise ArgumentError, "Line is not a string: #{line}" unless line.kind_of? String

      line.chomp! if  !line.nil?

      line.strip! if  !line.nil?

      #
      # A blank line, or a comment may be skipped.
      #
      return nil if  (line.nil?) || (line =~ /^#/) || (line.length < 1)

      #
      # Look for a time period.
      #
      if  line =~ /between\s+([0-9]+)-([0-9]+)/i

        #
        #  The starting/ending hours.
        #
        p_start = $1.dup.to_i
        p_end   = $2.dup.to_i

        #
        #  Get the current hour.
        #
        hour = Time.now.hour

        #
        #  Does the hour match the period?
        #
        inside = Custodian::Util::TimeSpan.inside?(p_start, p_end, hour)

        #
        #  Should we exclude the test?
        #
        if  line =~ /except\s+between/i
          return nil if  inside
        else
          return nil if  !inside
        end
      end

      #
      #  Look for macro definitions, inline
      #
      if  line =~ /^([0-9A-Z]_+)\s+are\s+fetched\s+from\s+([^\s]+)\.?/
        define_macro(line)

      elsif  line =~ /^([0-9A-Z_]+)\s+(is|are)\s+/
        define_macro(line)

      elsif  line =~ /^(\S+)\s+must\s+ping(.*)/
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
        return(parse_line(new_line))

      elsif  line =~ /^\S+\s+must(\s+not)?\s+run\s+([^\s]+)(\s+|\.|$)/i

        #
        # Expand the macro if we should
        #
        tests = expand_macro(line)

        #
        # The array of objects we will return to the caller.
        #
        ret = []

        #
        # For each host in our possibly-macro-expanded list:
        #
        tests.each do |macro_expanded|

          job = nil

          begin

            #
            #  We need to parse the job with the class-factory
            #
            #  BUT the key thing here is that the line is parseable,
            # not that we care about the result of that parsing.
            #
            # The result of the parsing will be an array and if so
            # we just need to store the first job.  Since it is duplicated
            # if there are multiple handlers and we should always have one -
            # or an unknown job-type of course!
            #
            job = Custodian::TestFactory.create(macro_expanded)

            if  job && (job.kind_of? Array)
              ret.push(job[0].to_s)
            end
          rescue => ex
            raise ArgumentError, "Parsing a line to a protocol test gave the error: #{ex}"
          end
        end

        return ret
      else
        raise ArgumentError, "Unknown line: '#{line}'"
      end
    end



    #
    # Parse a text-snippet, with multiple lines.
    #
    def parse_lines(text)

      #
      # If we're given a string then split it on newline
      #
      if  text.kind_of?(String)
        a    = text.split(/[\r\n]/)
        text = a
      end

      ret = nil

      #
      # Split on newline
      #
      text.each do |line|
        ret = parse_line(line)

        #
        #  The return value from the parse_line method
        # is either:
        #
        #  Array -> An array of test-objects.
        #
        #  nil   -> The line was a macro.
        #         or
        #           The line was a comment.
        #
        #
        if  ret.kind_of?(Array)
          ret.each do |probe|
            @jobs.push(probe)
          end
        end
      end

      ret
    end



    #
    # Parse the configuration file specified.
    #
    # This updates our @jobs array with the tests.
    #
    def parse_file(filename)

      raise ArgumentError, 'Missing configuration file!' if  filename.nil?
      raise ArgumentError, "File not found: #{@file}" unless  File.exist?(filename)

      #
      #  Read the configuration file.
      #
      out = File.open(filename, 'r') { |file| file.readlines.collect }

      #
      #  Parse it
      #
      parse_lines(out)
    end


  end


end
