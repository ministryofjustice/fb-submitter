class RemoveStatusFromSubmissions < ActiveRecord::Migration[5.2]
  def change
    remove_column :submissions, :status, :string
  end
end
