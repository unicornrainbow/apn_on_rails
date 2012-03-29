class APN::App < APN::Base

  has_many :groups, :class_name => 'APN::Group', :dependent => :destroy
  has_many :devices, :class_name => 'APN::Device', :dependent => :destroy
  has_many :notifications, :through => :devices, :dependent => :destroy
  has_many :unsent_notifications, :through => :devices
  has_many :group_notifications, :through => :groups
  has_many :unsent_group_notifications, :through => :groups

  def cert
    (Rails.env.production?? apn_prod_cert : apn_dev_cert)
  end

  # Opens a connection to the Apple APN server and attempts to batch deliver
  # an Array of group notifications.
  #
  #
  # As each APN::GroupNotification is sent the <tt>sent_at</tt> column will be timestamped,
  # so as to not be sent again.
  #
  def send_notifications
    if self.cert.nil?
      raise APN::Errors::MissingCertificateError.new
      return
    end
    APN::App.send_notifications_for_cert(self.cert, self.id)
  end

  def self.send_notifications
    APN::App.send_notifications_for_certs
    if !configatron.apn.cert.blank?
      global_cert = File.read(configatron.apn.cert)
      send_notifications_for_cert(global_cert, nil)
    end
  end

  def self.send_notifications_for_certs
    cert_column = (Rails.env.production?? 'apn_prod_cert' : 'apn_dev_cert')
    apps = APN::App.all(
      :conditions => "apn_apps.#{cert_column} is not null and apn_notifications.sent_at is null",
      :joins => { :devices => :notifications }
    )

    begin
      apps.each do |app|
        APN::Connection.open_for_delivery({:cert => app.cert}) do |conn, sock|
          app.devices.each do |dev|
            dev.notifications.each do |noty|
              if noty.sent_at.blank?
                conn.write(noty.message_for_sending)
                noty.sent_at = Time.now
                noty.save
              end
            end
          end
        end
      end
    rescue Exception => e
      log_connection_exception(e)
    end
  end

  def self.send_notifications_for_cert(the_cert, app_id)
    if (app_id == nil)
      conditions = "apn_devices.app_id is null and apn_notifications.sent_at is null"
    else
      conditions = ["apn_devices.app_id = ? and apn_notifications.sent_at is null", app_id]
    end
    if APN::Notification.count(:conditions => conditions, :joins => :device) > 0
      begin
        APN::Connection.open_for_delivery({:cert => the_cert}) do |conn, sock|
          sent = 0
          APN::Notification.find_each(:conditions => conditions, :include => :device) do |noty|
            if noty.sent_at.blank?
              conn.write(noty.message_for_sending)
              noty.touch :sent_at
              sent += 1
            end
          end
          return sent
        end
      rescue Exception => e
        log_connection_exception(e)
        e
      end
    end
  end

  def send_group_notifications
    if self.cert.nil?
      raise APN::Errors::MissingCertificateError.new
      return
    end
    unless self.unsent_group_notifications.nil? || self.unsent_group_notifications.empty?
      APN::Connection.open_for_delivery({:cert => self.cert}) do |conn, sock|
        unsent_group_notifications.each do |gnoty|
          gnoty.devices.find_each do |device|
            conn.write(gnoty.message_for_sending(device))
          end
          gnoty.sent_at = Time.now
          gnoty.save
        end
      end
    end
  end

  def send_group_notification(gnoty)
    if self.cert.nil?
      raise APN::Errors::MissingCertificateError.new
      return
    end
    unless gnoty.nil?
      APN::Connection.open_for_delivery({:cert => self.cert}) do |conn, sock|
        gnoty.devices.find_each do |device|
          conn.write(gnoty.message_for_sending(device))
        end
        gnoty.sent_at = Time.now
        gnoty.save
      end
    end
  end

  def self.send_group_notifications
    apps = APN::App.all
    apps.each do |app|
      app.send_group_notifications
    end
  end

  # Retrieves a list of APN::Device instnces from Apple using
  # the <tt>devices</tt> method. It then checks to see if the
  # <tt>last_registered_at</tt> date of each APN::Device is
  # before the date that Apple says the device is no longer
  # accepting notifications then the device is deleted. Otherwise
  # it is assumed that the application has been re-installed
  # and is available for notifications.
  #
  # This can be run from the following Rake task:
  #   $ rake apn:feedback:process
  def process_devices
    if self.cert.nil?
      raise APN::Errors::MissingCertificateError.new
      return
    end
    APN::App.process_devices_for_cert(self.cert)
  end # process_devices

  def self.process_devices
    apps = APN::App.all
    apps.each do |app|
      app.process_devices
    end
    if !configatron.apn.cert.blank?
      global_cert = File.read(configatron.apn.cert)
      APN::App.process_devices_for_cert(global_cert)
    end
  end

  def self.process_devices_for_cert(the_cert)
    puts "in APN::App.process_devices_for_cert"
    APN::Feedback.devices(the_cert).each do |device|
      if device.last_registered_at < device.feedback_at
        puts "device #{device.id} -> #{device.last_registered_at} < #{device.feedback_at}"
        device.destroy
      else
        puts "device #{device.id} -> #{device.last_registered_at} not < #{device.feedback_at}"
      end
    end
  end

  def self.log_connection_exception(ex)
    Rails.logger.error ex.message
  end

  protected
  def log_connection_exception(ex)
    Rails.logger.error ex.message
  end

end
