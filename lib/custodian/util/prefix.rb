

#
#  This class allows a custom-prefix to be prepended to any alert
#  subjects.
#
module Custodian

  module Util

    class Prefix


      #
      # Return the custom-prefix to use, if any.
      #
      def Prefix.text()
        # Default to no prefix.
        default = ""

        # Look for matches - last one wins.
        Dir.glob( "/store/clients/*/custodian-prefix.cfg" ).each do |file|
          begin
            default = File.read( file )
          rescue Errno::EACCES
            # Permission-denied.
          end
        end

        # Remove any newline characters
        default.gsub!( /[\r\n]/, '' )

        # Truncate, if required.
        max = 32
        default = default[0...max] if ( default.length > max )

        default
      end

    end
  end
end
