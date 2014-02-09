class PlayerTracking < ActiveRecord::Base
  belongs_to :user

  scope :most_common, -> { order(connection_count: :desc) }
end