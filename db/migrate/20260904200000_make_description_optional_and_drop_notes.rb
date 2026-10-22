class MakeDescriptionOptionalAndDropNotes < ActiveRecord::Migration[8.1]
  def change
    change_column_null :savings, :description, true
    remove_column :savings, :notes, :text
  end
end
