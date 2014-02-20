class Exit < ActiveRecord::Base
  belongs_to :destination, class_name: "Room"
end