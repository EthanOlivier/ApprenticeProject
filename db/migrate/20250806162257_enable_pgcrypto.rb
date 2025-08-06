class EnablePgcrypto < ActiveRecord::Migration[8.0]
  def change
    enable_extension 'pgcrypto' unless extension_enabled?('pgcrypto')
    change_column_default :leases, :id, -> { "gen_random_uuid()" }
  end
end
