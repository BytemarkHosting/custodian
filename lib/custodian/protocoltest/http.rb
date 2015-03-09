
require 'custodian/settings'
require 'timeout'
require 'uri'

#
#  The HTTP-protocol test.
#
#  This object is instantiated if the parser sees a line such as:
#
###
### http://foo.vm.bytemark.co.uk/ must run http with content 'page text' otherwise 'http fail'.
###
#
#
module Custodian

  module ProtocolTest


    class HTTPTest < TestFactory

      #
      # The line from which we were constructed.
      #
      attr_reader :line

      #
      # The URL to poll
      #
      attr_reader :url

      #
      # The expected status + content
      #
      attr_reader :expected_status, :expected_content

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
        @host = @url

        #
        # Set the resolve modes
        #
        @resolve_modes = []

        #
        # Will we follow redirects?
        #
        @redirect = true


        #
        #  Ensure we've got a HTTP/HTTPS url.
        #
        if ( @url !~ /^https?:/ )
          raise ArgumentError, "The target wasn't a HTTP/HTTPS URL: #{line}"
        end


        #
        # Determine that the protocol of the URL matches the
        # protocol-test we're running
        #
        test_type = nil

        case line
        when /\s+must\s(not\s+)?run\s+http(\s+|\.|$)/i
        then
          test_type = "http"
        when /\s+must\s+(not\s+)?run\s+https(\s+|\.|$)/i
        then
          test_type = "https"
        else
          raise ArgumentError, "URL has invalid scheme: #{@line}"
        end

        #
        #  Get the schema of the URL
        #
        u = URI.parse( @url )
        if ( u.scheme != test_type )
          raise ArgumentError, "The test case has a different protocol in the URI than that which we're testing: #{@line} - \"#{test_type} != #{u.scheme}\""
        end


        #
        # Is this test inverted?
        #
        if ( line =~ /must\s+not\s+run\s+/ )
          @inverted = true
        else
          @inverted = false
        end

        #
        # Expected status
        #
        if ( line =~ /with status ([0-9]+)/ )
          @expected_status = $1.dup
        else
          @expected_status = "200"
        end

        if ( line =~ /with (IPv[46])/i )
          @resolve_modes << $1.downcase.to_sym
        end

        #
        # The content we expect to find
        #
        if ( line =~ /with content '([^']+)'/ )
          @expected_content = $1.dup
        else
          @expected_content = nil
        end

        #
        # Do we follow redirects?
        #
        if ( line =~ /not following redirects?/i )
          @redirect = false
        end

        #
        # Do we use cache-busting?
        #
        @cache_busting = true
        if ( line =~ /with\s+cache\s+busting/ )
          @cache_busting = true
        end
        if ( line =~ /without\s+cache\s+busting/ )
          @cache_busting = false
        end
        
        # Do we need to override the HTTP Host: Header?
        @host_override = nil
        if ( line =~ /with host header '([^']+)'/)
          @host_override = $1.dup
        end
      end


      #
      #  Get the right type of this object, based on the URL
      #
      def get_type
        if ( @url =~ /^https:/ )
          "https"
        elsif ( @url =~ /^http:/ )
          "http"
        else
          raise ArgumentError, "URL isn't http/https: #{@url}"
        end
      end


      #
      #  Do we follow redirects?
      #
      def follow_redirects?
        @redirect
      end

      #
      #  Do we have cache-busting?
      #
      def cache_busting?
        @cache_busting
      end

      #
      # Allow this test to be serialized.
      #
      def to_s
        @line
      end



      #
      # Run the test.
      #
      def run_test

        #  Reset state, in case we've previously run.
        @error    = nil

        begin
          require 'rubygems'
          require 'curb'
        rescue LoadError
          @error = "The required rubygem 'curb' was not found."
          return false
        end

        #
        # Get the timeout period for this test.
        #
        settings = Custodian::Settings.instance()
        period   = settings.timeout()

        #
        # The URL we'll fetch/poll.
        #
        test_url = @url

        #
        #  Parse and append a query-string if not present, if we're
        # running with cache-busting.
        #
        if ( @cache_busting )
          u = URI.parse( test_url )
          if ( ! u.query )
            u.query   = "ctime=#{Time.now.to_i}"
            test_url  = u.to_s
          end
        end

        errors = []
        resolution_errors = []

        if @resolve_modes.empty?
          resolve_modes = [:ipv4, :ipv6]
        else
          resolve_modes = @resolve_modes
        end
                
        resolve_modes.each do |resolve_mode|
          status   = nil
          content  = nil

          c = Curl::Easy.new(test_url)

          c.resolve_mode = resolve_mode

          #
          # Should we follow redirections?
          #
          if ( follow_redirects? )
            c.follow_location = true
            c.max_redirects   = 10
          end
          
          unless @host_override.nil?
            c.headers["Host"] = @host_override
          end

          c.ssl_verify_host = false
          c.ssl_verify_peer = false
          c.timeout         = period

          #
          # Set a basic protocol message, for use later.
          #
          protocol_msg = (resolve_mode == :ipv4 ? "IPv4" : "IPv6")

          begin
            timeout( period ) do
              c.perform
              status = c.response_code
              content = c.body_str
            end

            #
            # Overwrite protocol_msg with the IP we connect to. 
            #
            if c.primary_ip
              if :ipv4 == resolve_mode
                protocol_msg = "#{c.primary_ip}" 
              else
                protocol_msg = "[#{c.primary_ip}]" 
              end
            end

          rescue Curl::Err::SSLCACertificateError => x
            errors << "#{protocol_msg}: SSL validation error: #{x.message}."
          rescue Curl::Err::TimeoutError, Timeout::Error
            errors << "#{protocol_msg}: Timed out fetching page."
          rescue Curl::Err::ConnectionFailedError
            errors << "#{protocol_msg}: Connection failed."
          rescue Curl::Err::TooManyRedirectsError
            errors << "#{protocol_msg}: More than 10 redirections."
          rescue Curl::Err::HostResolutionError
            # Nothing to see here..!
            resolution_errors << resolve_mode
          rescue => x
            errors << "#{protocol_msg}: #{x.class}: #{x.message}\n  #{x.backtrace.join("\n  ")}."
          end
  
          #
          # A this point we've either had an exception, or we've
          # got a result
          #
          if ( status and expected_status.to_i != status.to_i )
            errors << "#{protocol_msg}: Status code was #{status} not the expected #{expected_status}."
          end
  
          if ( content.is_a?(String) and 
               expected_content.is_a?(String) and 
               content !~ /#{expected_content}/i )
            errors << "#{protocol_msg}: The response did not contain our expected text '#{expected_content}'."
          end
        end

        # uh-oh! Resolution failed on both protocols!
        if resolution_errors.length > 1
          errors << "Hostname did not resolve for #{resolution_errors.join(", ")}"
        end

        if errors.length > 0
          if @host_override
            errors << "Host header was overridden as Host: #{@host_override}"
          end
          @error = errors.join("\n")
          return false
        end
  
        #
        #  All done.
        #
        return true
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
  end
end
