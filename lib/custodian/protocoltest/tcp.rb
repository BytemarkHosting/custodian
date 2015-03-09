
require 'custodian/settings'
require 'custodian/testfactory'
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
module Custodian

  module ProtocolTest

    class TCPTest < TestFactory


      #
      # The input line from which we were constructed.
      #
      attr_reader :line


      #
      # The host to test against.
      #
      attr_reader :host


      #
      # The port to connect to.
      #
      attr_reader :port


      #
      # Is this test inverted?
      #
      attr_reader :inverted


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
        # Save the line
        #
        @line = line

        #
        # Save the host
        #
        @host  = line.split( /\s+/)[0]

        #
        # Is this test inverted?
        #
        if  line =~ /must\s+not\s+run\s+/ 
          @inverted = true
        else
          @inverted = false
        end

        #
        # Save the port
        #
        if  line =~ /on\s+([0-9]+)/ 
          @port = $1.dup
        else
          @port = nil
        end

        #
        # Save the optional banner.
        #
        if  line =~ /with\s+banner\s+'([^']+)'/ 
          @banner = $1.dup
        else
          @banner = nil
        end

        @error = nil

        if  @port.nil? 
          raise ArgumentError, 'Missing port to test against'
        end
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

        # reset the error, in case we were previously executed.
        @error = nil

        ( run_test_internal( @host, @port, @banner, ( ! @banner.nil? ) ) )
      end



      #
      # Run the connection test - optionally matching against the banner.
      #
      # If the banner is nil then we're merely testing we can connect and
      # send the string "quit".
      #
      # There are two ways this method will be invoked, via the configuration file:
      #
      #         foo.vm.bytemark.co.uk must run tcp on 24 with banner 'smtp'
      # or
      #         1.2.3.44 must run tcp on 53 otherwise 'named failed'.
      #
      # Here we're going to try to resolve the hostname in the first version
      # into both IPv6 and IPv4 addresses and test them both.
      #
      # A failure in either version will result in a failure.
      #
      def run_test_internal( host, port, banner = nil, do_read = false )

        #
        # Get the timeout period.
        #
        settings = Custodian::Settings.instance
        period   = settings.timeout

        #
        # Perform the DNS lookups of the specified name.
        #
        ips = []

        #
        #  Does the name look like an IP?
        #
        begin
          x = IPAddr.new( host )
          if  x.ipv4? or x.ipv6? 
            ips.push( host )
          end
        rescue ArgumentError
          #
          # NOP - Just means the host wasn't an IP
          #
        end

        #
        #  Both types?
        #
        do_ipv6 = true
        do_ipv4 = true

        #
        # Allow the test to disable one/both
        #
        if  @line =~ /ipv4_only/ 
          do_ipv6 = false
        end
        if  @line =~ /ipv6_only/ 
          do_ipv4 = false
        end


        #
        # OK if it didn't look like an IP address then attempt to
        # look it up, as both IPv4 and IPv6.
        #
        begin
          timeout( period ) do

            Resolv::DNS.open do |dns|

              if  do_ipv4 
                ress = dns.getresources(host, Resolv::DNS::Resource::IN::A)
                ress.map { |r| ips.push( r.address.to_s ) }
              end
              if  do_ipv6 
                ress = dns.getresources(host, Resolv::DNS::Resource::IN::AAAA)
                ress.map { |r| ips.push( r.address.to_s ) }
              end
            end
          end
        rescue Timeout::Error => e
          @error = "Timed-out performing DNS lookups: #{e}"
          return nil
        end


        #
        #  Did we fail to perform a DNS lookup?
        #
        if  ips.empty? 
          @error = "#{@host} failed to resolve to either IPv4 or IPv6"
          return false
        end


        #
        # Run the test, avoiding the use of the shell, for each of the
        # IPv4 and IPv6 addresses we discovered, or the host that we
        # were given.
        #
        ips.each do |ip|
          if  ! run_test_internal_real( ip, port, banner, do_read ) 

            return false
            #
            # @error will be already set.
            #
          end
        end


        #
        #  All was OK
        #
        @error = nil
        true
      end



      #
      # Run the connection test - optionally matching against the banner.
      #
      # If the banner is nil then we're merely testing we can connect and
      # send the string "quit".
      #
      # This method will ONLY ever be invoked with an IP-address for a
      # destination.
      #
      def run_test_internal_real( host, port, banner = nil, do_read = false )

        #
        # Get the timeout period for this test.
        #
        settings = Custodian::Settings.instance
        period   = settings.timeout

        begin
          timeout(period) do
            begin
              socket = TCPSocket.new( host, port )

              # read a banner from the remote server, if we're supposed to.
              read = nil
              read = socket.sysread(1024) if  do_read 

              # trim to a sane length & strip newlines.
              if  ! read.nil? 
                read = read[0,255]
                read.gsub!(/[\n\r]/, '')
              end

              socket.close

              if  banner.nil? 
                @error = nil
                return true
              else
                # test for banner

                # regexp.
                if  banner.kind_of? Regexp 
                  if  ( !read.nil? ) && ( banner.match(read) ) 
                    return true
                  end
                end

                # string.
                if  banner.kind_of? String 
                  if  ( !read.nil? ) && ( read =~ /#{banner}/i ) 
                    return true
                  end
                end

                @error = "We expected a banner matching '#{banner}' but we got '#{read}'"
                return false
              end
            rescue
              @error = "Exception connecting to host #{host}:#{port} - #{$ERROR_INFO}"
              return false
            end
          end
        rescue Timeout::Error => e
          @error = "TIMEOUT: #{e}"
          return false
        end
        @error = 'Misc failure'
        false
      end




      #
      # If the test fails then report the error.
      #
      def error
        @error
      end




      register_test_type 'tcp'




    end
  end
end
