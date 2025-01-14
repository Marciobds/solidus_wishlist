class Spree::Wishlist < ActiveRecord::Base
  belongs_to :user, class_name: 'Spree::User'
  has_many :wished_products, dependent: :destroy
  has_many :visible_wished_products,
    -> { joins(:variant).where(spree_variants: {deleted_at: nil}) },
    class_name: "Spree::WishedProduct"
  before_create :set_access_hash

  validates :name, presence: true

  def include?(variant_id)
    wished_products.where(variant_id: variant_id.to_i).exists?
  end

  def to_param
    access_hash
  end

  def self.get_by_param(param)
    Spree::Wishlist.find_by_access_hash(param)
  end

  def can_be_read_by?(user)
    !self.is_private? || user == self.user
  end

  def is_default=(value)
    self[:is_default] = value
    return unless is_default?
    Spree::Wishlist.where(is_default: true, user_id: user_id).where.not(id: id).update_all(is_default: false)
  end

  def is_public?
    !self.is_private?
  end

  private

  def set_access_hash
    random_string = SecureRandom.hex(16)
    self.access_hash = Digest::SHA1.hexdigest("--#{user_id}--#{random_string}--#{Time.now}--")
  end
end
