class CreateContactInfos < ActiveRecord::Migration[6.1]
  def change
    create_table :contact_infos do |t|
      t.string :name
      t.string :email
      t.string :phone

      t.timestamps
    end
  end
end
