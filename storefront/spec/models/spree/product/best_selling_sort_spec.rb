require 'spec_helper'

RSpec.describe 'Product best selling sort', type: :model do
  let(:store) { @default_store }
  let!(:product1) { create(:product, name: 'Running Jacket', stores: [store]) }
  let!(:product2) { create(:product, name: 'Waterproof Shoes', stores: [store]) }
  let!(:product3) { create(:product, name: 'Warming gloves', stores: [store]) }
  let!(:product4) { create(:product, name: 'Product out of stock', stores: [store]) }
  let!(:product6) { create(:product, name: 'Product for free', stores: [store]) }

  before do
    create_list(:completed_order_with_totals, 3, store: store, line_items_price: 10, variants: [product1.master])
    create_list(:completed_order_with_totals, 5, store: store, line_items_price: 10, variants: [product2.master])
    create_list(:completed_order_with_totals, 3, store: store, line_items_price: 6, variants: [product3.master])
    create_list(:completed_order_with_totals, 6, store: store, line_items_price: 10, variants: [product6.master])

    [product1, product2, product3, product4, product6].each do |product|
      product.store_products.find_by!(store: store).refresh_metrics!
    end
  end

  it 'orders products by units sold' do
    product_ids = [product1, product2, product3, product4, product6].map(&:id)

    expect(store.products.where(id: product_ids).by_best_selling.map(&:name)).to eq [
      product6.name,
      product2.name,
      product1.name,
      product3.name,
      product4.name
    ]
  end
end
