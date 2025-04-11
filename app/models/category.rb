class Category < ApplicationRecord
  has_many :product_categories, dependent: :destroy
  has_many :products, through: :product_categories
  validates :name, presence: true,
            length: {maximum: Settings.max_category_name_length}

  def self.ransackable_attributes _auth_object = nil
    %w(name)
  end
end
