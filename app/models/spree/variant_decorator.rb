module Spree
  module VariantDecorator
  	def self.prepended(base)
	 	base.has_many :wished_products, dependent: :destroy
	end

	::Spree::Variant.prepend self
  end
end