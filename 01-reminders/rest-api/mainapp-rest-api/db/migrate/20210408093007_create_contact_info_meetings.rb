class CreateContactInfoMeetings < ActiveRecord::Migration[6.1]
  def change
    create_table :contact_info_meetings do |t|
      t.references :contact_info, null: false, foreign_key: true
      t.references :meeting, null: false, foreign_key: true

      t.timestamps
    end
  end
end
