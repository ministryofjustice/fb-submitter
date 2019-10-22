class RemoveSubmissionTypeFromSubmissions < ActiveRecord::Migration[5.2]
  def change
    remove_column :submissions, :submission_type, :string, nil: true
  end
end
