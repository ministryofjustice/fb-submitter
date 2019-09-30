require 'rails_helper'

RSpec.describe DbSweeper do
  describe '#call' do
    context 'when there are submissions over 28 days old' do
      before do
        create(:submission, created_at: 30.days.ago)
        create(:submission, created_at: 5.days.ago)
      end

      it 'destroys the older records' do
        expect do
          subject.call
        end.to change(Submission, :count).by(-1)
      end
    end

    context 'when there are no submissions over 28 days old' do
      before do
        create(:submission, created_at: 5.days.ago)
      end

      it 'leaves records intact' do
        expect do
          subject.call
        end.not_to change(Submission, :count)
      end
    end
  end
end
