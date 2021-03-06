class JobMailer < ApplicationMailer
  default from: 'no-reply-preassembly-job@stanford.edu'

  def completion_email
    @job_run = params[:job_run]
    @user = @job_run.bundle_context.user
    mail(to: @user.email, subject: @job_run.mail_subject)
  end
end
