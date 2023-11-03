require 'rails_helper'

describe HealthController do
  describe 'GET #show' do
    it 'returns 200 OK' do
      get :show
      expect(response.status).to eq(200)
    end

    it 'returns healthy body' do
      get :show
      expect(response.body).to eq('healthy')
    end
  end

  describe 'GET #readiness' do
    context 'when the database is up and running' do
      it 'returns 200 OK' do
        get :readiness
        expect(response.status).to eq(200)
      end

      it 'returns `ready` body' do
        get :readiness
        expect(response.body).to eq('ready')
      end
    end

    context 'when the database is not ready yet' do
      before do
        allow(ActiveRecord::Base).to receive(:connected?).and_return(false)
      end

      it 'returns 503 service unavailable' do
        get :readiness
        expect(response.status).to eq(503)
      end

      it 'returns `not_ready` body' do
        get :readiness
        expect(response.body).to eq('not_ready')
      end
    end
  end
end
