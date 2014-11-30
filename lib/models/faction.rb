class Faction < ActiveRecord::Base
  extend Enumerize

  enumerize :hostility, in: {low_reputation: 1, always: 2, never: 3}

  has_many :reputations
end