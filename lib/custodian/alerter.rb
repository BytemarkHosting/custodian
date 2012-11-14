

require 'mauve/sender'
require 'mauve/proto'



#
#  This class encapsulates the raising and clearing of alerts via Mauve.
#
class Alerter

  attr_reader :details

  def initialize( test_details )
    @details = test_details
  end


  #
  # Raise the alert.
  #
  def raise( detail )

    update = Mauve::Proto::AlertUpdate.new
    update.alert   = []
    update.source  = "custodian"

    # be explicit about raising/clearing
    update.replace = false

    alert            = Mauve::Proto::Alert.new

    # e.g. ping-example.vm.bytemark.co.uk
    # e.g. http-http://example.com/page1
    alert.id         = "#{@details['test_type']}-#{@details['target_host']}"

    alert.subject    = @details['target_host']
    alert.summary    = @details['test_alert']
    alert.detail     = "The #{@details['test_type']} test failed against #{@details['target_host']}: #{detail}"
    alert.raise_time = Time.now.to_i
    update.alert << alert

    Mauve::Sender.new("alert.bytemark.co.uk").send(update)

  end

  #
  #  Clear the alert.
  #
  def clear

    update = Mauve::Proto::AlertUpdate.new
    update.alert   = []
    update.source  = "custodian"

    # be explicit about raising/clearing
    update.replace = false


    alert            = Mauve::Proto::Alert.new

    # e.g. ping-example.vm.bytemark.co.uk
    # e.g. http-http://example.com/page1
    alert.id         = "#{@details['test_type']}-#{@details['target_host']}"

    alert.subject    = @details['target_host']
    alert.summary    = @details['test_alert']
    alert.detail     = "The #{@details['test_type']} test succeeded against #{@details['target_host']}"
    alert.clear_time = Time.now.to_i
    update.alert << alert

    Mauve::Sender.new("alert.bytemark.co.uk").send(update)
  end

end
