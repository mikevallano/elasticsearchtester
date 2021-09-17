class RenameNameToTitle < ActiveRecord::Migration[6.1]
  def up
    rename_column :books, :name, :title
  end

  def down
    rename_column :books, :title, :name
  end
end
