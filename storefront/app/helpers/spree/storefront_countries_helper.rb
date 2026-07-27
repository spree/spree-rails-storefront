module Spree
  # Rails' `include_all_helpers` mixes every engine helper into every view, so
  # `Spree::Admin::BaseHelper#available_countries` (which builds bare
  # `Spree::Country.new(iso:)` records for admin autocompletes) can shadow
  # `Spree::BaseHelper#available_countries` in storefront views. Those records
  # have no `id` or `name`, which renders the address form country select as
  # empty options.
  #
  # `Spree::StoreController` includes this module and exposes it via
  # `helper_method`, which takes precedence over mixed-in helper modules, so
  # storefront views get the storefront implementation.
  module StorefrontCountriesHelper
    def available_countries
      @storefront_available_countries ||= current_store.countries_available_for_checkout.map do |country|
        country.name = localized_country_name(country)
        country
      end.sort_by { |country| country.name.parameterize }
    end
  end
end
