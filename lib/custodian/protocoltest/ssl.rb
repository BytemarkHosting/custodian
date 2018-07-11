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

  ALL_TESTS = [:signature, :valid_from, :valid_to, :subject, :sslv3_disabled, :signing_algorithm]

  attr_reader :errors

  # This is a helper for console-debugging.
  def verbose(msg)
    (msg)
  end

  #
  # Takes one parameter -- the URL.
  #
  def initialize(uri, expiry_days = 14)
    raise ArgumentError, 'URI must be a string' unless uri.is_a?(String)
    @uri = URI.parse(uri)

    @domain = @uri.host
    @key = nil

    @expiry_days = expiry_days

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
    raise ArgumentError, 'domain must be a String' unless d.is_a?(String)
    @domain = d
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
    raise ArgumentError, 'tests must be an Array' unless ts.is_a?(Array)
    @tests = ts.collect { |t| t.to_sym }.select { |t| ALL_TESTS.include?(t) }

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
    raise ArgumentError, 'key must be a String' unless k.is_a?(String)
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
      raise ArgumentError, 'bundle must be a String, an Array, or an OpenSSL::X509::Certificate'
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
    @certificate_store.add_path('/etc/ssl/certs')
    @certificate_store
  end

  #
  # This is a fall-back method which is used to retrieve the certificate
  # from the remote host in the case where fetching natively fails.
  #
  # It is obviously not a great method, because we shouldn't need to
  # be shelling out to a command-line application over using our
  # native/available SSL library.
  #
  # Beyond the ropy nature of this method there is another problem:
  # we cannot fetch the bundle the remote-server might send us.
  #
  # So if this method is used `@fallback` is set to `true` such that
  # we only validate the certificate is non-expired, and not that it
  # is valid.
  #
  def certificate_fallback
    cert = ""
    in_cert = false

    # Run the command.
    out = `echo "" | timeout --kill-after=12s 10s openssl s_client -servername #{uri.host} -connect #{uri.host}:#{uri.port} 2>/dev/null`
    # For each line of the output
    out.split( /[\r\n]/ ).each do |line|

      # Are we in a certificate?
      in_cert = true if ( line =~ /BEGIN CERT/ )

      # If so append the line.
      if ( in_cert )
        cert += line
        cert += "\n"
      end

      # Are we at the end?
      in_cert = false if ( line =~ /END CERT/ )
    end

    # Return the certificate
    cert
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
      Timeout.timeout(10) do
        s = TCPSocket.open(uri.host, uri.port)
        s = OpenSSL::SSL::SSLSocket.new(s, ctx)
        s.sync_close = true

        # Setup a hostname for SNI-purposes.
        begin
          s.hostname = uri.host
        rescue NoMethodError => _err
          # SNI isn't possible, as the SSL library is too old.
        end

        s.connect
        @certificate = s.peer_cert
        self.bundle = s.peer_cert_chain
        s.close
      end
    rescue OpenSSL::SSL::SSLError => err
      unless retried
        #
        # retry with a different context
        #
        retried = true
        ctx = OpenSSL::SSL::SSLContext.new(:SSLv3_client)
        retry
      end
      self.errors << verbose("*Caught #{err.class}* (#{err}) when connecting to #{uri.host}:#{uri.port}")

    rescue StandardError, Timeout::Error => err
      self.errors << verbose("*Caught #{err.class}* (#{err}) when connecting to #{uri.host}:#{uri.port}")
    ensure
      s.close if s.respond_to?(:close) and !s.closed?
    end

    @certificate
  end

  #
  # This performs the verification tests.
  #
  def verify
    if self.tests.empty?
      verbose "All tests have been disabled for #{self.domain}"
      return true
    end

    # Did we fail to find the certificate?
    if self.certificate.nil?

      # Use our fallback method.
      fallback = certificate_fallback()

      # If we failed to fetch it then we cannot do anything useful.
      if ( fallback.nil? )
        self.errors << verbose("Failed to fetch certificate for #{self.domain}")
	return nil
      else
        # Populate the certificate, and report that we used our
        # fallback method - because we've no longer got access
        # to the bundle the remote server might have sent us.
        @fallback    = true
        @certificate = OpenSSL::X509::Certificate.new(fallback)
      end
    end

    return ![verify_subject, verify_valid_from, verify_valid_to, verify_signature].any? { |r| false == r }
  end

  def verify_sslv3_disabled
    unless self.tests.include?(:sslv3_disabled)
      verbose "Skipping SSLv3 test for #{self.domain}"
      return true
    end

    s = nil
    begin
      Timeout.timeout(10) do
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

    false
  end

  def verify_signing_algorithm
    unless self.tests.include?(:signing_algorithm)
      verbose "Skipping signing algorithm check for #{self.domain}"
      return true
    end
    if self.certificate.signature_algorithm.start_with? 'sha1'
      self.errors << verbose("Certificate for #{self.domain} is signed with a weak algorithm (SHA1) and should be reissued.")
      return false
    else
      return true
    end
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
      verbose "The certificate for #{self.domain} is valid from #{self.certificate.not_before}."
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

    days_until_expiry = (self.certificate.not_after.to_i - Time.now.to_i) / (24.0 * 3600).floor.to_i

    if days_until_expiry > @expiry_days
      verbose "The certificate for #{self.domain} is valid until #{self.certificate.not_after}."
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
    #
    # If we used our fallback method we cannot verify that the
    # signature is valid, because we're missing the bundle that
    # the remote server should have sent us.
    #
    if ( @fallback )
      verbose "Skipping certificate signature validation for #{self.domain} because fallback SSL-certificate had to be used and we think we'll fail"
      return true;
    end

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
      verbose "Using a self-signed certificate for #{self.domain}."
      return true

    #
    # Otherwise see if we can verify it using the certificate store,
    # including any bundle that has been uploaded.
    #
    elsif self.certificate_store.is_a?(OpenSSL::X509::Store) and self.certificate_store.verify(self.certificate)
      verbose "Certificate signed by #{self.certificate.issuer}"
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
      def initialize(line)

        #
        #  Save the line
        #
        @line = line

        if @line =~ /and cannot expire within (\d+) days/ then
          @expiry_days = $1.to_i
        else
          @expiry_days = 14
        end

        #
        # Save the host
        #
        @host = line.split(/\s+/)[0]

      end


      #
      # Return the expiry period we'll test against
      #
      def expiry_days
        @expiry_days
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
        if @line =~ /no_ssl_check/
          return Custodian::TestResult::TEST_PASSED
        end


        #
        #  Get the current hour.
        #
        hour = Time.now.hour

        #
        #  If outside 10AM-5PM we don't run the test.
        #
        if hour < 10 || hour > 17
          puts("Outside office hours - Not running SSL-Verification of #{@host}")
          return Custodian::TestResult::TEST_SKIPPED
        end

        #
        #  Double-check we've got an SSL host
        #
        if !@host =~ /^https:\/\//
          puts('Not an SSL URL')
          return Custodian::TestResult::TEST_SKIPPED
        end

        s = SSLCheck.new(@host,@expiry_days)
        result = s.verify

        if true == result
          puts("SSL Verification succeeded for #{@host}")
          return Custodian::TestResult::TEST_PASSED
        elsif result.nil?
          puts("SSL Verification returned no result #{@host}")
          @error = "SSL Verification for #{@host} failed - TLS negotiation failure?\n";
          @error += s.errors.join("\n")
          return Custodian::TestResult::TEST_FAILED
        else
          puts("SSL Verification for #{@host} has failed.")
          @error = "SSL Verification for #{@host} failed: "
          @error += s.errors.join("\n")
          return Custodian::TestResult::TEST_FAILED
        end

      end


      #
      # If the test fails then report the error.
      #
      def error
        @error
      end


      #
      # Override the base behaviour so that we get a better failure
      # summary.
      #
      def get_type
        'ssl-validity'
      end


      register_test_type 'https'

    end
  end
end
