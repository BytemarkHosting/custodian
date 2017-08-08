
require 'custodian/settings'
require 'custodian/testfactory'

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
      # Should we ignore a (temporary) DNS error in this test?
      #
      # We've been beset by a series of false-alerts in the recent
      # past which have all occurred at this point:
      #
      #   * We get bogus errors in resolving DNS from curb/libcurl.
      #
      #   * These errors go away on retry.
      #
      #   * But the retry isn't fast enough to outrace the
      #     supression-time of our alerts.
      #
      # For the moment we're going to _temporarily_ ignore these errors.
      #
      #  * If a host has Connection-Refused, the wrong status-cde
      #    or similar failure it will be handled as normal.
      #
      #  * If the host has genuinely lost DNS then we're going to
      #    raise an alert, but if it is this false-error then we
      #    will silently disable this test-run.
      #
      def ignore_failure?

        #  IP addresses we found for the host
        ips = []

        # Get the hostname we're connecting to.
        u = URI.parse(@url)
        target = u.host

        #
        #  Resolve the target to an IP, unless it is already an address.
        #
        if (target =~ /^([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)$/) ||
           (target =~ /^([0-9a-f:]+)$/)
          ips.push(target)
        else

          #
          # OK if it didn't look like an IP address then attempt to
          # look it up, as both IPv4 and IPv6.
          #
          begin
            timeout(30) do

              Resolv::DNS.open do |dns|

                ress = dns.getresources(target, Resolv::DNS::Resource::IN::A)
                ress.map { |r| ips.push(r.address.to_s) }

                ress = dns.getresources(target, Resolv::DNS::Resource::IN::AAAA)
                ress.map { |r| ips.push(r.address.to_s) }
              end
            end
          rescue Timeout::Error => _e
            # NOP
          end
        end

        #
        #  At this point we either have:
        #
        #   "ips" containing entries - because the hostname resolved
        #
        #   "ips" being empty because the DNS failure was genuine
        #
        return ( ! ips.empty? )
      end



      #
      # Constructor
      #
      def initialize(line)

        #
        #  Save the line
        #
        @line = line

        #
        #  Save the URL
        #
        @url = line.split(/\s+/)[0]
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
        # No basic-authentication by default
        #
        @username = nil
        @password = nil

        #
        #  Ensure we've got a HTTP/HTTPS url.
        #
        if @url !~ /^https?:/
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
          test_type = 'http'
        when /\s+must\s+(not\s+)?run\s+https(\s+|\.|$)/i
        then
          test_type = 'https'
        else
          raise ArgumentError, "URL has invalid scheme: #{@line}"
        end

        #
        #  Get the schema of the URL
        #
        u = URI.parse(@url)
        if (u.scheme != test_type)
          raise ArgumentError, "The test case has a different protocol in the URI than that which we're testing: #{@line} - \"#{test_type} != #{u.scheme}\""
        end

        #
        #  Save username/password if they were specified
        #
        @username = u.user if ( u.user )
        @password = u.password if ( u.password )

        #
        # Expected status
        #
        if line =~ /with status ([0-9]+)/
          @expected_status = $1.dup
        else
          @expected_status = '200'
        end

        if line =~ /with (IPv[46])/i
          @resolve_modes << $1.downcase.to_sym
        end

        #
        # The content we expect to find
        #
        if line =~ /with content (["'])(.*?)\1/
          @expected_content = $2.dup
        else
          @expected_content = nil
        end

        #
        # Do we follow redirects?
        #
        if line =~ /not following redirects?/i
          @redirect = false
        end

        #
        # Do we use cache-busting?
        #
        @cache_busting = true
        if line =~ /with\s+cache\s+busting/
          @cache_busting = true
        end
        if line =~ /without\s+cache\s+busting/
          @cache_busting = false
        end

        # Do we need to override the HTTP Host: Header?
        @host_override = nil
        if line =~ /with host header '([^']+)'/
          @host_override = $1.dup
        end

         # We can't test on IPv4-only or IPv6-only basis
         if line =~ /ipv[46]_only/i
          raise ArgumentError, 'We cannot limit HTTP/HTTPS tests to IPv4/IPv6-only'
         end

      end


      #
      #  Get the right type of this object, based on the URL
      #
      def get_type
        if @url =~ /^https:/
          'https'
        elsif @url =~ /^http:/
          'http'
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
      #  Do we have basic auth?
      #
      def basic_auth?
        ( @username.nil? == false ) && ( @password.nil? == false )
      end

      #
      #  Get the username/password for basic-auth
      #
      def basic_auth_username
        @username
      end

      def basic_auth_password
        @password
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
        # Reset state, in case we've previously run.
        @error = nil

        begin
          require 'rubygems'
          require 'curb'
        rescue LoadError
          @error = "The required rubygem 'curb' was not found."
          return Custodian::TestResult::TEST_FAILED
        end

        # Get the timeout period for this test.
        settings = Custodian::Settings.instance
        period = settings.timeout

        #
        # The URL we'll fetch/poll.
        #
        test_url = @url

        #
        #  Parse and append a query-string if not present, if we're
        # running with cache-busting.
        #
        if @cache_busting
          u = URI.parse(test_url)
          if !u.query
            u.query = "ctime=#{Time.now.to_i}"
            test_url = u.to_s
          end
        end

        #
        #  If we're running with HTTP-basic-auth we should remove
        # the username/password from the URL we're passing to curb.
        #
        if ( basic_auth? )
          u = URI.parse(test_url)
          u.user     = nil
          u.password = nil
          test_url = u.to_s
        end

        errors = []
        resolution_errors = []

        resolve_modes = [:ipv4, :ipv6]
        resolve_modes = @resolve_modes if !@resolve_modes.empty?

        resolve_modes.each do |resolve_mode|
          status = nil
          content = nil

          c = Curl::Easy.new(test_url)

          c.resolve_mode = resolve_mode

          #
          # Should we use HTTP basic-auth?
          #
          if  basic_auth?
            c.http_auth_types = :basic
            c.username = basic_auth_username
            c.password = basic_auth_password
          end

          #
          # Should we follow redirections?
          #
          if follow_redirects?
            c.follow_location = true
            c.max_redirects = 10
          end

          unless @host_override.nil?
            c.headers['Host'] = @host_override
          end

          c.ssl_verify_host = false
          c.ssl_verify_peer = false
          c.timeout = period

          #
          # Set a basic protocol message, for use later.
          #
          protocol_msg = (resolve_mode == :ipv4 ? 'IPv4' : 'IPv6')

          begin
            timeout(period) do
              c.perform
              status = c.response_code
              content = c.body_str
            end

            #
            # Overwrite protocol_msg with the IP we connect to.
            #
            if c.primary_ip
              if :ipv4 == resolve_mode
                protocol_msg = c.primary_ip.to_s
              else
                protocol_msg = "[#{c.primary_ip}]"
              end
            end

          rescue Curl::Err::RecvError => x
            errors << "#{protocol_msg}: Receive error: #{x.message}."
          rescue Curl::Err::SSLCACertificateError => x
            errors << "#{protocol_msg}: SSL validation error: #{x.message}."
          rescue Curl::Err::TimeoutError, Timeout::Error
            errors << "#{protocol_msg}: Timed out fetching page."
          rescue Curl::Err::ConnectionFailedError
            errors << "#{protocol_msg}: Connection failed."
          rescue Curl::Err::TooManyRedirectsError
            errors << "#{protocol_msg}: More than 10 redirections."
          rescue Curl::Err::HostResolutionError => x
            resolution_errors << "#{protocol_msg}: #{x.class}: #{x.message}\n  #{x.backtrace.join("\n  ")}."

          rescue => x
            errors << "#{protocol_msg}: #{x.class}: #{x.message}\n  #{x.backtrace.join("\n  ")}."
          end

          #
          # A this point we've either had an exception, or we've
          # got a result
          #
          if status and expected_status.to_i != status.to_i
            errors << "#{protocol_msg}: Status code was #{status} not the expected #{expected_status}."
          end

          if content.is_a?(String) and
            expected_content.is_a?(String) and
            content !~ /#{expected_content}/i
            errors << "#{protocol_msg}: The response did not contain our expected text '#{expected_content}'."
          end
        end

        # uh-oh! Resolution failed on both protocols!
        if resolution_errors.length > 1

          return Custodian::TestResult::TEST_SKIPPED if ignore_failure?

          errors << "DNS Error when resolving host - #{resolution_errors.join(',')}"
        end

        if !errors.empty?
          if @host_override
            errors << "Host header was overridden as Host: #{@host_override}"
          end
          @error = errors.join("\n")
          return Custodian::TestResult::TEST_FAILED
        end

        #
        #  All done.
        #
        Custodian::TestResult::TEST_PASSED
      end

      #
      # If the test fails then report the error.
      #
      def error
        @error
      end


      register_test_type 'http'
      register_test_type 'https'

    end
  end
end
