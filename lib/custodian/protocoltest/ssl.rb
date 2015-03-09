require 'custodian/testfactory'

require 'openssl'
require 'socket'
require 'uri'
require 'timeout'



#
#  This is the class which tests the SSL certificate associated with a
# given URL.
#
class SSLCheck

  ALL_TESTS = [:signature, :valid_from, :valid_to, :subject, :sslv3_disabled]

  attr_reader :errors

  # This is a helper for console-debugging.
  def verbose( msg )
    return(msg)
  end

  #
  # Takes one parameter -- the URL.
  #
  def initialize(uri)
    raise ArgumentError, "URI must be a string" unless uri.is_a?(String)
    @uri = URI.parse(uri)

    @domain = @uri.host
    @key = nil

    @certificate = nil
    @certificate_store = nil

    @tests = ALL_TESTS

    @errors = []
  end

  #
  # Returns the URI
  #
  def uri
    @uri
  end

  alias :url :uri

  #
  # Returns the domain.  This is initially set to the "host" part of the URI.
  #
  def domain
    @domain
  end

  #
  # Allows the domain to be set manually.
  #
  def domain=(d)
    raise ArgumentError, "domain must be a String" unless d.is_a?(String)
    @domain=d
  end

  #
  # Returns the tests to be carried out for this URI
  #
  def tests
    @tests
  end

  #
  # Allows the tests to be set.  Should an array of strings or symbols.  Only
  # ones from ALL_TESTS are taken.  Anything else is ignored.
  #
  def tests=(ts)
    raise ArgumentError, "tests must be an Array" unless ts.is_a?(Array)
    @tests = ts.collect{|t| t.to_sym}.select{|t| ALL_TESTS.include?(t)}

    @tests
  end

  #
  # Returns the SSL key (if any)
  #
  def key
    @key
  end

  #
  # Allows an SSL RSA key to be set.  Used for self-signed cert verification.
  # Probably not much use here.
  #
  def key=(k)
    raise ArgumentError, "key must be a String" unless k.is_a?(String)
    if k =~ /-----BEGIN/
      @key = OpenSSL::PKey::RSA.new(k)
    else
      @key = OpenSSL::PKey::RSA.new(File.read(k))
    end
  end

  #
  # This allows a bundle to be set.  This is useful if a site is known to be
  # serving a good cert+bundle, but for some reason openssl isn't validating it
  # properly.
  #
  # This method is also used to include any peer_cert_chain from the SSL socket.
  #
  def bundle=(b)
    if b.is_a?(String)
      if b =~ /-----BEGIN CERT/
        self.certificate_store.add_cert(OpenSSL::X509::Certificate.new(b))
      else
        self.certificate_store.add_file(b)
      end
    elsif b.is_a?(Array)
      b.each do |c|
        begin
          self.certificate_store.add_cert(c)
        rescue OpenSSL::X509::StoreError
          # do nothing ..
        end
      end
    elsif b.is_a?(OpenSSL::X509::Certificate)
      self.certificate_store.add_cert(b)
    else
      raise ArgumentError, "bundle must be a String, an Array, or an OpenSSL::X509::Certificate"
    end
    b
  end

  #
  # This returns the certificate store used for validating certs.
  #
  def certificate_store
    return @certificate_store if @certificate_store.is_a?(OpenSSL::X509::Store)

    @certificate_store = OpenSSL::X509::Store.new
    @certificate_store.set_default_paths
    @certificate_store.add_path("/etc/ssl/certs")
    @certificate_store
  end

  #
  # This connects to a host, and fetches its certificate and bundle
  #
  def certificate
    return @certificate if @certificate.is_a?(OpenSSL::X509::Certificate)

    s = nil
    ctx = OpenSSL::SSL::SSLContext.new(:TLSv1_client)
    retried = false
    begin
      Timeout::timeout(10) do
        s = TCPSocket.open(uri.host, uri.port)
        s = OpenSSL::SSL::SSLSocket.new(s, ctx)
        s.sync_close = true

        # Setup a hostname for SNI-purposes.
        begin
          s.hostname = uri.host
        rescue NoMethodError => err
          # SNI isn't possible, as the SSL library is too old.
        end

        s.connect
        @certificate = s.peer_cert
        self.bundle = s.peer_cert_chain
        s.close
      end
    rescue OpenSSL::SSL::SSLError => err
      unless retried
        # retry with a different context
        #
        ctx = OpenSSL::SSL::SSLContext.new(:SSLv3_client)
        retry
      end
      self.errors << verbose("*Caught #{err.class}* (#{err}) when connecting to #{uri.host}:#{uri.port}")

    rescue StandardError, Timeout::Error => err
      self.errors << verbose("*Caught #{err.class}* (#{err}) when connecting to #{uri.host}:#{uri.port}")
    ensure
      s.close if s.respond_to?(:close) and !s.closed?
    end

    return @certificate
  end

  #
  # This performs the verification tests.
  #
  def verify
    if self.tests.empty?
      verbose "All tests have been disabled for #{self.domain}"
      return true
    elsif self.certificate.nil?
      self.errors << verbose("Failed to fetch certificate for #{self.domain}")
      return nil
    else
      return ![ verify_subject, verify_valid_from, verify_valid_to, verify_signature].any?{|r| false == r}
    end
  end

  def verify_sslv3_disabled
    unless self.tests.include?(:sslv3_disabled)
      verbose "Skipping SSLv3 test for #{self.domain}"
      return true
    end

    s = nil
    begin
      Timeout::timeout(10) do
        s = TCPSocket.open(uri.host, uri.port)
        s = OpenSSL::SSL::SSLSocket.new(s, OpenSSL::SSL::SSLContext.new(:SSLv3_client))
        s.sync_close = true
        s.connect
        s.close
      end
      self.errors << verbose("*SSLv2 or SSLv3 enabled* on #{uri.host}:#{uri.port}")
      return false
    rescue OpenSSL::SSL::SSLError => err
      #
      # OK good :)
      #
      return true
    rescue StandardError, Timeout::Error => err
      self.errors << verbose("*Caught #{err.class}* (#{err}) when connecting to #{uri.host}:#{uri.port} using SSLv3")
    ensure
      s.close if s.respond_to?(:close) and !s.closed?
    end

    return false
  end

  def verify_subject
    unless self.tests.include?(:subject)
      verbose "Skipping subject verification for #{self.domain}"
      return true
    end

    #
    # Firstly check that the certificate is valid for the domain or one of its aliases.
    #
    if OpenSSL::SSL.verify_certificate_identity(self.certificate, self.domain)
      verbose "The certificate subject is valid for #{self.domain}"
      return true
    else
      self.errors << verbose("The certificate subject is *not valid* for this domain #{self.domain}.")
      return false
    end
  end

  def verify_valid_from
    unless self.tests.include?(:valid_from)
      verbose "Skipping certificate end date validation for #{self.domain}"
      return true
    end

    #
    # Check that the certificate is current
    #
    if self.certificate.not_before < Time.now
      verbose  "The certificate for #{self.domain} is valid from #{self.certificate.not_before}."
      return true
    else
      self.errors << verbose("The certificate for #{self.domain} *is not valid yet*.")
      return false
    end
  end

  def verify_valid_to
    unless self.tests.include?(:valid_to)
      verbose "Skipping certificate start date validation for #{self.domain}"
      return true
    end

    days_until_expiry = (self.certificate.not_after.to_i - Time.now.to_i)/(24.0*3600).floor.to_i

    if days_until_expiry > 14
      verbose  "The certificate for #{self.domain} is valid until #{self.certificate.not_after}."
      return true
    else
      if days_until_expiry > 0
        self.errors << verbose("The certificate for #{self.domain} *will expire in #{days_until_expiry} days*.")
      else
        self.errors << verbose("The certificate for #{self.domain} *has expired*.")
      end
      return false
    end
  end

  def verify_signature
    unless self.tests.include?(:signature)
      verbose "Skipping certificate signature validation for #{self.domain}"
      return true
    end

    #
    # Now check the signature.
    #
    # First see if we can verify it using our own private key, i.e. the
    # certificate is self-signed.
    #
    if self.key.is_a?(OpenSSL::PKey) and self.certificate.verify(self.key)
      verbose  "Using a self-signed certificate for #{self.domain}."
      return true

    #
    # Otherwise see if we can verify it using the certificate store,
    # including any bundle that has been uploaded.
    #
    elsif self.certificate_store.is_a?(OpenSSL::X509::Store) and self.certificate_store.verify(self.certificate)
      verbose  "Certificate signed by #{self.certificate.issuer}"
      return true

    #
    # If we can't verify -- raise an error.
    #
    else
      self.errors << verbose("Certificate *signature does not verify* for #{self.domain} -- maybe a bundle is missing?")
      return false
    end
  end

end




#
#  The SSL-expiry test.
#
#  This object is instantiated if the parser sees a line such as:
#
###
### https://foo.vm.bytemark.co.uk/ must run https with content 'page text' otherwise 'http fail'.
###
#
#
module Custodian

  module ProtocolTest

    class SSLCertificateTest < TestFactory


      #
      # Constructor
      #
      def initialize( line )

        #
        #  Save the line
        #
        @line = line

        #
        # Save the host
        #
        @host = line.split( /\s+/)[0]

      end




      #
      # Allow this test to be serialized.
      #
      def to_s
        @line
      end



      #
      # Run the test - this means making a TCP-connection to the
      # given host and validating that the SSL-certificate is not
      # expired.
      #
      # Because testing the SSL certificate is relatively heavy-weight
      # and because they don't change often we only test in office-hours.
      #
      #
      def run_test

        #
        #  If the line disables us then return early
        #
        if ( @line =~ /no_ssl_check/ )
          return true
        end


        #
        #  Get the current hour.
        #
        hour = Time.now.hour

        #
        #  If outside 10AM-5PM we don't run the test.
        #
        if ( hour < 10 || hour > 17 )
          puts( "Outside office hours - Not running SSL-Verification of #{@host}" )
          return true
        end

        #
        #  Double-check we've got an SSL host
        #
        if ( ! @host =~ /^https:\/\// )
          puts( "Not an SSL URL" )
          return true
        end

        s = SSLCheck.new(@host)
        result = s.verify

        if true == result
          puts( "SSL Verification succeeded for #{@host}" )
          return true
        elsif result.nil?
          puts( "SSL Verification returned no result (timeout?) #{@host}" )
          return true
        else
          puts( "SSL Verification for #{@host} has failed." )
          @error  = "SSL Verification for #{@host} failed: ";
          @error +=  s.errors.join("\n")
          return false
        end

      end


      #
      # If the test fails then report the error.
      #
      def error
        @error
      end

      register_test_type "https"

    end
  end
end
