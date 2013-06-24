#!/usr/bin/ruby1.8

module Custodian

  module Util

    #
    # A class for working with time-spans.
    #
    class TimeSpan

      #
      #  Given a starting hour such as 10pm and and ending hour such as 4am
      # see if the current hour is inside that range.
      #
      def TimeSpan.inside?( p_start, p_end, cur_hour = nil)

        #
        #  If we don't have an hour specified then use the current one.
        #
        if ( cur_hour.nil? )
          cur_hour = Time.now.hour
        end

        #
        #  Convert "XXPM" to appropriate 24-hour based integers
        #
        if ( ( p_start.kind_of? String ) && ( p_start =~ /([0-9]+)pm$/i ) )
          p_start = $1.dup.to_i + 12;
        end
        if ( ( p_end.kind_of? String ) && ( p_end =~ /([0-9]+)pm$/i ) )
          p_end = $1.dup.to_i + 12;
        end
        if ( ( cur_hour.kind_of? String ) && ( cur_hour =~ /([0-9]+)pm$/i ) )
          cur_hour = $1.dup.to_i + 12;
        end

        #
        #  If we have AM suffixes then strip them
        #
        if ( p_start.kind_of? String )
          p_start = p_start.sub( /am$/, '' )
          p_start = p_start.to_i
        end
        if ( p_end.kind_of? String )
          p_end = p_end.sub( /am$/, '' )
          p_end = p_end.to_i
        end
        if ( cur_hour.kind_of? String )
          cur_hour = cur_hour.sub( /am$/, '' )
          cur_hour = cur_hour.to_i
        end


        #
        #  Ensure we're now left with integer values.
        #
        raise ArgumentError, "Integer required for start time"   unless( p_start.kind_of? Integer )
        raise ArgumentError,  "Integer required for end time"     unless( p_end.kind_of? Integer )
        raise ArgumentError,  "Integer required for current hour" unless( cur_hour.kind_of? Integer )

        #
        #  Ensure the values have appropriate bounds.
        #
        raise ArgumentError,  "Invalid start time"   unless( ( p_start >= 0 ) && ( p_start <= 23 ) )
        raise ArgumentError,  "Invalid end time"     unless( ( p_end >= 0 ) && ( p_end <= 23 ) )
        raise ArgumentError,  "Invalid current time" unless( ( cur_hour >= 0 ) && ( cur_hour <= 23 ) )

        #
        #  Valid hours, within the span
        #
        valid = {}

        #
        #  Iterate over the hours.  Store in a hash.
        #
        hour = p_start
        while( hour != p_end )
          valid[hour] = 1
          hour += 1
          hour  = 0 if ( hour >= 23 )
        end
        valid[p_end]=1

        # now do the test.
        ( valid[cur_hour] == 1 )
      end

    end
  end
end


