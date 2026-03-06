module Spree
  module Storefront
    module StoreDecorator
      def self.prepended(base)
        base.include Spree::Stores::Socials

        base.has_rich_text :checkout_message

        # Add social network fields to translatable fields
        base.translates(:facebook, :twitter, :instagram, column_fallback: !Spree.always_use_translations?)
      end
    end
  end
end

Spree::Store.prepend(Spree::Storefront::StoreDecorator)
