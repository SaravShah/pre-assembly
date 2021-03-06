RSpec.describe 'job_runs/show.html.erb', type: :view do
  let(:job_run) { create(:job_run) }

  before { assign(:job_run, job_run) }

  it 'displays a job_run' do
    render
    expect(rendered).to include("Discovery report \##{job_run.id}")
  end

  it 'with an output_location, presents a download link' do
    render
    expect(rendered).to include("<a href=\"/job_runs/#{job_run.id}/download\">Download</a>")
  end

  it 'without an output_location, urges user patience' do
    job_run.output_location = nil
    render
    expect(rendered).to include('Job is not yet complete')
  end

  it 'displays user email from bundle context' do
    render
    expect(rendered).to include(job_run.bundle_context.user.email)
  end
end
