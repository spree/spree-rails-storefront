require 'spec_helper'

# Regression coverage for the storefront `available_countries` helper.
#
# Rails' `include_all_helpers` mixes every engine helper into every view, so
# `Spree::Admin::BaseHelper#available_countries` (which builds bare
# `Spree::Country.new(iso:)` records for admin autocompletes) can shadow the
# storefront implementation. Those records have no `id` or `name`, which renders
# the address form country select as empty options.
describe 'Address form country select' do
  let!(:country) { create(:country) }
  let(:order) { create(:order_with_line_items, user_id: nil, store: Spree::Store.default) }

  it 'renders options with the country name and id' do
    visit "/checkout/#{order.token}"

    expect(page).to have_select('order_ship_address_attributes_country_id', with_options: [country.name])

    option = find("#order_ship_address_attributes_country_id option[value='#{country.id}']", visible: :all)
    expect(option.text).to eq(country.name)
  end

  it 'resolves the storefront implementation, not the admin one' do
    controller = Spree::StoreController.new

    expect(controller.respond_to?(:localized_country_name, true)).to be(true)
    expect(Spree::StoreController.ancestors).to include(Spree::StorefrontCountriesHelper)
  end
end
