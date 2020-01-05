class Item < ApplicationRecord
  has_one :address
  has_many :images, dependent: :destroy
  accepts_nested_attributes_for :images, allow_destroy: true
end

