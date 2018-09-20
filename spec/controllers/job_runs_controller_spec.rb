RSpec.describe JobRunsController, type: :controller do
  before { sign_in(create(:user)) }

  describe 'GET #show' do
    it 'returns http success' do
      allow(JobRun).to receive(:find).with('123').and_return(instance_double(JobRun))
      get :show, params: { id: 123 }
      expect(response).to have_http_status(:success)
    end

    it 'requires ID param' do
      expect { get :show }.to raise_error(ActionController::UrlGenerationError)
    end
  end
end