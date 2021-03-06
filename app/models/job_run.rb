class JobRun < ApplicationRecord
  belongs_to :bundle_context
  validates :job_type, presence: true
  after_create :enqueue!
  after_update :send_notification, if: -> { saved_change_to_output_location? }
  after_initialize :default_enums

  enum job_type: {
    'discovery_report' => 0,
    'preassembly' => 1
  }

  # throw to asynchronous processing via correct Job class for job_type
  # @return [ApplicationJob, nil] nil if unpersisted
  def enqueue!
    return nil unless persisted?
    "#{job_type.camelize}Job".constantize.perform_later(self)
  end

  # @return [String] Subject line for notification email
  def mail_subject
    "[#{bundle_context.project_name}] Your #{job_type.humanize} job completed"
  end

  def send_notification
    return unless output_location
    JobMailer.with(job_run: self).completion_email.deliver_later
  end

  # @return [DiscoveryReport]
  def to_discovery_report
    @to_discovery_report ||= DiscoveryReport.new(bundle_context.bundle)
  end

  private

  def default_enums
    self[:job_type] ||= 0
  end
end
