class Track < ApplicationRecord
	has_many :played_tracks
	has_many :queued_tracks
end
