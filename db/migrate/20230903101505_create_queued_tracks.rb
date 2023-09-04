class CreateQueuedTracks < ActiveRecord::Migration[7.0]
  def change
    create_table :queued_tracks do |t|
      t.references :track, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
