class CreatePlayedTracks < ActiveRecord::Migration[7.0]
  def change
    create_table :played_tracks do |t|
      t.references :track, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
