require 'tmpdir'
require 'fileutils'

module Custodian

  module Util

    class Tftp

      attr_reader :hostname, :port, :filename

      #
      # Store hostname and port
      #
      def initialize(hostname, port=69)
      
        raise ArgumentError, 'Hostname must not be nil' if  hostname.nil?
        raise ArgumentError, 'Hostname must be a String' unless  hostname.kind_of?(String)
        raise ArgumentError, 'Port must be a number' unless port.to_i > 0

        @hostname = hostname
        @port = port.to_i
      end

      #
      # Returns true only if the file can be downloaded and is not zero-length.
      #
      def test(file)
        target = Dir::Tmpname.make_tmpname('/tmp/', nil)

        return false unless fetch(file, target)
        return false unless File.size?(target)
        return true
      ensure
        FileUtils.rm_f(target)
      end

      def fetch(file, target=nil)
        # HPA's tftp client appears to have a 25s timeout that it is
        # not possible to change on the command line.
        return tftp("-m binary #{@hostname} #{@port} -c get #{file} #{target}")
      end

      def tftp(args)
        return system("tftp #{args}") == true
      end

    end

  end

end
