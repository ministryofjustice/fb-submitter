require 'rails_helper'

RSpec.describe DbSweeper do
  describe '#call' do
    context 'when there are submissions over 28 days old' do
      let(:thirty_day_submission) { create(:submission, created_at: 30.days.ago) }
      let(:five_day_submission) { create(:submission, created_at: 5.days.ago) }

      before do
        create(:email_payload, submission_id: thirty_day_submission.id)
        create(:email_payload, submission_id: five_day_submission.id)
      end

      it 'destroys the older submission records and associated email payload records' do
        expect {
          subject.call
        }.to change(Submission, :count).by(-1).and change(EmailPayload, :count).by(-1)
      end
    end

    context 'when there are no submissions over 28 days old' do
      let(:submission) { create(:submission, created_at: 5.days.ago) }

      before do
        create(:email_payload, submission_id: submission.id)
      end

      it 'leaves submission and email payload records intact' do
        expect(Submission.all.count).to eq(1)
        expect(EmailPayload.all.count).to eq(1)
      end
    end
  end
end
