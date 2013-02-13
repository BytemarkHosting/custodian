require 'custodian/protocoltest/tcp'


#
#  The LDAP-protocol test.
#
#  This object is instantiated if the parser sees a line such as:
#
###
### foo.vm.bytemark.co.uk must run ldap with username 'user' and password 'xx' otherwise 'auth-server fail'.
###
#
#  The specification of the port is optional and defaults to 389.
#
module Custodian

  module ProtocolTest

    class LDAPTest < TestFactory


      #
      # Constructor
      #
      def initialize( line )

        #
        # Save the line.
        #
        @line = line

        #
        # Save the host
        #
        @host  = line.split( /\s+/)[0]

        #
        # The username/password
        #
        @ldap_user = nil
        @ldap_pass = nil

        if ( line =~ /with\s+username\s+'([^']+)'/ )
          @ldap_user = $1.dup
        end
        if ( line =~ /with\s+password\s+'([^']+)'/ )
          @ldap_pass = $1.dup
        end

        if ( @ldap_user.nil? )
          raise ArgumentError, "No username specified: #{@line}"
        end
        if ( @ldap_pass.nil? )
          raise ArgumentError, "No password specified: #{@line}"
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
        # Save the port
        #
        if ( line =~ /on\s+([0-9]+)/ )
          @port = $1.dup
        else
          @port = 389
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

        run_test_internal( @host, @port, nil, false )
      end




      #
      # If the test fails then report the error.
      #
      def error
        @error
      end




      register_test_type "ldap"




    end
  end
end
