class RemoveResponsesAndSubmissionDetailsFromSubmissions < ActiveRecord::Migration[5.2]
  def change
    remove_column :submissions, :responses, :json
    remove_column :submissions, :submission_details, :json
  end
end
