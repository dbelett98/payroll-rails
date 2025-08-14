class RenamePasswordDigestToEncryptedPassword < ActiveRecord::Migration[7.1]
  def change
    rename_column :users, :password_digest, :encrypted_password
  end
end