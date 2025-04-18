class Review < ApplicationRecord
  REVIEW_PARAMS = %i(rating comment).freeze
  validates :rating, presence: true,
            numericality: {only_integer: true,
                           greater_than_or_equal_to: Settings.min_rating,
                           less_than_or_equal_to: Settings.max_rating}
  validates :comment, presence: true,
            length: {maximum: Settings.max_comment_length}
  belongs_to :order
  belongs_to :product

  scope :by_product_id, ->(product_id){where product_id:}
end
