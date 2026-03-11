module Spree
  module Storefront
    module StoreDecorator
      def self.prepended(base)
        base.include Spree::Stores::Socials

        base.has_rich_text :checkout_message

        # Storefront-specific attachments
        base.has_one_attached :favicon_image, service: Spree.public_storage_service_name
        base.has_one_attached :social_image, service: Spree.public_storage_service_name

        base.validates :favicon_image, :social_image, content_type: Rails.application.config.active_storage.web_image_content_types

        # Storefront-specific preferences
        base.preference :index_in_search_engines, :boolean, default: false
        base.preference :password_protected, :boolean, default: false

        # Storefront password (stored in private_metadata)
        base.store_accessor :private_metadata, :storefront_password

        # Add social network fields to translatable fields
        base.translates(:facebook, :twitter, :instagram, column_fallback: !Spree.always_use_translations?)
      end

      def favicon
        return unless favicon_image.attached? && favicon_image.variable?

        favicon_image.variant(resize_to_limit: [32, 32])
      end
    end
  end
end

Spree::Store.prepend(Spree::Storefront::StoreDecorator)
