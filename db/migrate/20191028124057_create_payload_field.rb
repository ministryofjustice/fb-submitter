class CreatePayloadField < ActiveRecord::Migration[5.2]
  def change
    add_column :submissions, :payload, :json
  end
end
