require 'custodian/protocoltest/tcp'

require 'ldap'

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
          @port = $1.dup.to_i
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

        begin
          #
          #  Connect.
          #
          ldap = LDAP::Conn.new( @host, @port )
          ldap.set_option(LDAP::LDAP_OPT_PROTOCOL_VERSION, 3)

          #
          #  Hardwired search is bad..
          #
          base = 'ou=groups,dc=bytemark,dc=co,dc=uk'
          scope = LDAP::LDAP_SCOPE_SUBTREE
          filter = '(cn=vpn*)'
          attrs = ['sn', 'cn']

          #
          #  Bind.
          #
          ldap.bind( @ldap_user, @ldap_pass )
          if ( ldap.bound? )

            #
            # Search
            #
            ldap.search(base,scope,filter,attrs)  { |entry|
              puts "We found an LDAP result #{entry.vals('cn')}"
            }
            ldap.unbind
            return true
          else
            @error = "failed to bind to LDAP server '#{@host}' with username '#{@ldap_user}' and password '#{@ldap_pass}'"
            return false.
          end
        end
      rescue LDAP::ResultError => ex
        @error = "LDAP exception: #{ex} when talkign to LDAP server '#{@host}' with username '#{@ldap_user}' and password '#{@ldap_pass}'"
        return false
      end

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
