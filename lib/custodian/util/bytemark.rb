

require 'ipaddr'



#
# This class contains some Bytemark-specific tests/code.
#
module Custodian

  module Util

    class Bytemark


      #
      # The currently allocated IP-ranges which belong to Bytemark.
      #
      # These are used to test if an alert refers to a machine outwith our
      # network.
      #
      BYTEMARK_RANGES = %w(80.68.80.0/20 89.16.160.0/19 212.110.160.0/19 46.43.0.0/18 91.223.58.0/24 213.138.96.0/19 5.153.224.0/21 2001:41c8::/32 2001:41c9::/32).collect{|i| IPAddr.new(i)}


      #
      # Is the named target inside the Bytemark IP-range?
      #
      def Bytemark.inside?( target )
        inside = false

        if ( BYTEMARK_RANGES.any?{|range| range.include?(IPAddr.new(target))} )
          inside = true
        end

        inside
      end



    end
  end
end
