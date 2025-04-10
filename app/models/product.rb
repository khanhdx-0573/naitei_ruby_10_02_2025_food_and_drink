class Product < ApplicationRecord
  acts_as_paranoid
  SORT_OPTIONS = [
    [I18n.t("product.sort.default"), ""],
    [I18n.t("product.sort.price_asc"), Settings.sort_price_asc],
    [I18n.t("product.sort.price_desc"), Settings.sort_price_desc],
    [I18n.t("product.sort.name_asc"), Settings.sort_name_asc],
    [I18n.t("product.sort.name_desc"), Settings.sort_name_desc]
  ].freeze
  PRODUCT_PARAMS = [:name, :description, :price, {category_ids: []}].freeze
  validates :name, presence: true,
            length: {maximum: Settings.max_product_name_length}
  validates :price, presence: true,
            numericality: {greater_than: Settings.min_price}
  validates :description, presence: true,
            length: {maximum: Settings.max_description_length}
  validates :image,
            content_type: {
              in: Settings.image_types,
              message: I18n.t("product.image_format")
            },
            size: {
              less_than: Settings.max_image_size.megabytes,
              message: I18n.t("product.image_size")
            }
  has_one_attached :image
  has_many :reviews, dependent: :destroy
  has_many :order_items, dependent: :destroy
  has_many :product_categories, dependent: :destroy
  has_many :categories, through: :product_categories

  scope :by_ids, ->(ids){where id: ids}
  scope :by_category, lambda {|category_id|
    if category_id.present?
      joins(:product_categories).where(product_categories: {category_id:})
    end
  }
  scope :by_date_updated, ->{order updated_at: :desc}
  scope :by_sort, lambda {|sort|
    sort_options = {
      Settings.sort_name_asc => {name: :asc},
      Settings.sort_name_desc => {name: :desc},
      Settings.sort_price_asc => {price: :asc},
      Settings.sort_price_desc => {price: :desc}
    }
    order(sort_options[sort])
  }

  scope :filtered, lambda {|params, user|
    ransack(params[:q], auth_object: user)
      .result
      .by_category(params[:category_id])
      .distinct
  }
  scope :featured_products, (lambda do
    joins(:order_items)
      .group("products.id")
      .order("COUNT(order_items.id) DESC")
      .limit(Settings.home_page_items)
  end)

  ransacker :updated_at, type: :date do
    Arel.sql("DATE(products.updated_at)")
  end

  def self.ransackable_attributes auth_object
    if auth_object&.admin?
      %w(name price updated_at)
    else
      %w(name price)
    end
  end

  def self.ransackable_associations _auth_object = nil
    %w(categories)
  end

  def self.ransackable_scopes _auth_object = nil
    %i(by_sort)
  end
end
