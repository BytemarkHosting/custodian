
module Custodian

  module Util

    #
    # A class for working with time-spans.
    #
    class TimeSpan


      #
      # Convert an hour-string into a sane integer.
      #
      def TimeSpan.to_hour(desc)

        #
        #  Handle PM times.
        #
        if  (desc.kind_of? String) &&
             (desc =~ /([0-9]+)pm$/i) 
          desc = $1.dup.to_i + 12
        end

        #
        #  Handle AM times.
        #
        if  desc.kind_of? String 
          desc = desc.sub(/am$/, '')
          desc = desc.to_i
        end

        #
        #  Ensure within a valid range
        #
        raise ArgumentError, 'Integer required for time'   unless(desc.kind_of? Integer)
        raise ArgumentError,  "Invalid time: #{desc}" unless((desc >= 0) && (desc <= 23))


        #
        # Return the updated string.
        #
        desc
      end




      #
      # Given a start/end string convert that
      # to a hash of hours which are inside the
      # range - inclusively.
      #
      def TimeSpan.to_hours(p_start, p_end)

        p_start = Custodian::Util::TimeSpan.to_hour(p_start)
        p_end   = Custodian::Util::TimeSpan.to_hour(p_end)


        #
        #  Valid hours, within the span
        #
        valid = {}


        #
        #  Iterate over the hours.  Store in a hash.
        #
        hour = p_start
        while(hour != p_end)
          valid[hour] = 1
          hour += 1
          hour  = 0 if  hour > 23 
        end
        valid[p_end]=1

        #
        #  Return the hash
        #
        valid
      end




      #
      # Given a starting hour, such as 10pm, and an ending hour,
      # such as 4am, test whether a time is within that period.
      #
      def TimeSpan.inside?(p_start, p_end, cur_hour = nil)

        #
        # Default to the current hour, if not specified.
        #
        if  cur_hour.nil? 
          cur_hour = Time.now.hour
        end

        #
        # Ensure all values are sane and reasonable.
        #
        p_start  = Custodian::Util::TimeSpan.to_hour(p_start)
        p_end    = Custodian::Util::TimeSpan.to_hour(p_end)
        cur_hour = Custodian::Util::TimeSpan.to_hour(cur_hour)

        #
        #  Get the expanded hours
        #
        valid =
          Custodian::Util::TimeSpan.to_hours(p_start, p_end)

        #
        # Lookup to see if the specified hour is within the
        # hours between the range.
        #
        (valid[cur_hour] == 1)
      end

    end
  end
end
