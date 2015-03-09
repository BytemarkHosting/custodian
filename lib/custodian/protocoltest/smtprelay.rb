require 'net/smtp'



#
#  The open SMTP-relay test.
#
#  This object is instantiated if the parser sees a line such as:
#
###
### mail.bytemark.co.uk must not run smtprelay otherwise 'smtp fail'.
###
#
#  The specification of the port is optional and defaults to 25
#

module Custodian

  module ProtocolTest

    class SMTPRelayTest < TestFactory


      #
      # Save away state from the configuration line.
      #
      def initialize( line )
        @line = line
        @host = line.split( /\s+/)[0]

        #
        # Save the port
        #
        if ( line =~ /on\s+([0-9]+)/ )
          @port = $1.dup
        else
          @port = 25
        end

        #
        # Is this test inverted?
        #
        if ( line =~ /must\s+not\s+run\s+/ )
          @inverted = true
        else
          @inverted = false
        end
      end



      #
      # Allow this test to be serialized.
      #
      def to_s
          @line
      end


      #
      # Read the hostname for usage in the SMTP-transaction.
      #
      def get_hostname
        hostname = "localhost.localdomain"

        if ( File.exist?( "/etc/hostname" ) )
          File.readlines("/etc/hostname" ).each do |line|
            hostname = line if ( !line.nil? )
            hostname.chomp!
          end
        end

        hostname
      end



      #
      # run the test for open relays of SMTP protocol - return true on success.
      # false on fail.
      #
      def run_test
        # for if we've run the test before
        @error  = nil
        message = "Subject: SMTP Relay check\nThis is a test for OPEN SMTP relays."

        begin

          Net::SMTP.start(@host,@port, get_hostname() ) do |smtp|
            sent    = smtp.send_message message, "noreply@bytemark.co.uk", "noreply@bytemark.co.uk"
            @status = sent.status.to_s

            if @status === "250"
              @error = "NOT OK: message sent on #{@host} with status #{@status}"
            else
              @error = "OK: message not sent on #{@host} with status #{@status}"
            end

            #
            # give the parser an appropriate response depending on the smtp code
            # and whether or not we're inverting the test. (eg, 'must not')
            #

            return @inverted  if @status == "250" and @inverted
            return !@inverted if @status == "250" and !@inverted
            return @inverted  if @status != "250" and !@inverted
            return !@inverted if @status != "250" and @inverted

          end # Net SMTP

        rescue StandardError => ex
          #
          # for if we fail to send a message; this is a good thing
          #
          @error = "OK: Timed out or connection refused on #{@host} with status #{@status}"
          return !@inverted if @inverted
          return @inverted if !@inverted
        end

      end


      #
      # If the test failed here we will return a suitable error message.
      #
      def error
        @error
      end

      # register ourselves with the class-factory
      register_test_type "smtprelay"
    end
  end
end
