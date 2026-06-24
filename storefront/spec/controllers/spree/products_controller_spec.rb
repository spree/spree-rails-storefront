require 'spec_helper'

describe Spree::ProductsController, type: :controller do
  render_views

  let(:store) { @default_store }
  let(:product) { create(:product, stores: [store]) }
  let(:preview_id) { nil }

  describe '#index' do
    subject { get :index }

    it 'renders the Shop All page' do
      subject

      expect(response).to render_template(:index)
      expect(assigns(:current_page)).to be_a(Spree::Pages::ShopAll)
    end

    describe 'pagination' do
      let!(:products) { create_list(:product, 25, stores: [store]) }

      context 'with Pagy (default)' do
        before { Spree::Storefront::Config[:use_kaminari_pagination] = false }

        it 'paginates products with Pagy' do
          subject
          expect(assigns(:pagy)).to be_a(Pagy::Offset)
          expect(assigns(:storefront_products).size).to eq(20) # default per_page
        end

        it 'returns correct page info' do
          subject
          expect(assigns(:pagy).page).to eq(1)
          expect(assigns(:pagy).pages).to eq(2)
          expect(assigns(:pagy).count).to eq(25)
        end

        it 'returns next page' do
          get :index, params: { page: 2 }
          expect(assigns(:pagy).page).to eq(2)
          expect(assigns(:storefront_products).size).to eq(5)
        end
      end

      context 'with Kaminari' do
        before { Spree::Storefront::Config[:use_kaminari_pagination] = true }
        after { Spree::Storefront::Config[:use_kaminari_pagination] = false }

        it 'paginates products with Kaminari' do
          subject
          expect(assigns(:pagy)).to be_nil
          expect(assigns(:storefront_products)).to respond_to(:total_pages)
          expect(assigns(:storefront_products).size).to eq(20)
        end

        it 'returns correct page info' do
          subject
          expect(assigns(:storefront_products).current_page).to eq(1)
          expect(assigns(:storefront_products).total_pages).to eq(2)
          expect(assigns(:storefront_products).total_count).to eq(25)
        end

        it 'returns next page' do
          get :index, params: { page: 2 }
          expect(assigns(:storefront_products).current_page).to eq(2)
          expect(assigns(:storefront_products).size).to eq(5)
        end
      end
    end

    context 'when filtering' do
      let(:taxon) { create(:taxon) }

      context 'by one taxon' do
        let(:product) { create(:product, stores: [store], taxons: [taxon]) }

        before do
          product
          get :index, params: { filter: { taxon_ids: [taxon.id] } }
        end

        it 'returns one product' do
          expect(assigns(:storefront_products).records).to eq([product])
        end
      end

      context 'by taxonomies' do
        let(:taxonomy) { create(:taxonomy) }
        let(:taxon) { create(:taxon, taxonomy: taxonomy) }
        let(:taxon2) { create(:taxon, taxonomy: taxonomy) }
        let(:product) { create(:product, stores: [store], taxons: [taxon]) }
        let(:product2) { create(:product, stores: [store], taxons: [taxon2]) }

        before do
          product
          product2
          get :index, params: { filter: { taxonomy_ids: taxonomy_ids } }
        end

        context 'when one taxonomy is selected' do
          context 'and both taxons are selected' do
            let(:taxonomy_ids) { { taxonomy.id => { taxon_ids: [taxon.id, taxon2.id] } } }

            it 'returns both products' do
              expect(assigns(:storefront_products).records).to eq([product, product2])
            end
          end

          context 'and only one taxon is selected' do
            let(:taxonomy_ids) { { taxonomy.id => { taxon_ids: [taxon.id] } } }

            it 'returns only the product associated with the selected taxon' do
              expect(assigns(:storefront_products).records).to eq([product])
            end
          end

          context 'when no taxons are selected' do
            let(:taxonomy_ids) { { taxonomy.id => { taxon_ids: [] } } }

            it 'returns all products' do
              expect(assigns(:storefront_products).records).to eq([product, product2])
            end
          end
        end

        context 'when multiple taxonomies are selected' do
          let(:taxonomy2) { create(:taxonomy) }
          let(:taxon3) { create(:taxon, taxonomy: taxonomy2) }
          let(:product3) { create(:product, stores: [store], taxons: [taxon3, taxon]) }

          before do
            product3
            get :index, params: { filter: { taxonomy_ids: taxonomy_ids } }
          end

          context 'and product matches both taxons from both taxonomies exactly' do
            let(:taxonomy_ids) { { taxonomy.id => { taxon_ids: [taxon.id] }, taxonomy2.id => { taxon_ids: [taxon3.id] } } }

            it 'returns products associated with the selected taxons' do
              expect(assigns(:storefront_products).records).to eq([product3])
            end
          end

          context 'and product matches only one taxonomy completely' do
            let(:taxonomy_ids) { { taxonomy.id => { taxon_ids: [taxon.id] }, taxonomy2.id => { taxon_ids: [taxon3.id] } } }
            let(:product3) { create(:product, stores: [store], taxons: [taxon3]) }

            it 'returns no products' do
              expect(assigns(:storefront_products).records).to eq([])
            end
          end

          context 'and product matches none of the taxons' do
            let(:taxonomy_ids) { { taxonomy.id => { taxon_ids: [taxon.id] }, taxonomy2.id => { taxon_ids: [taxon3.id] } } }
            let(:product3) { create(:product, stores: [store], taxons: [taxon2]) }

            it 'returns no products' do
              expect(assigns(:storefront_products).records).to eq([])
            end
          end

          context 'and product matches all taxons from one taxonomy and partially from another' do
            let(:taxonomy_ids) { { taxonomy.id => { taxon_ids: [taxon.id] }, taxonomy2.id => { taxon_ids: [taxon2.id, taxon3.id] } } }
            let(:product3) { create(:product, stores: [store], taxons: [taxon, taxon2]) }

            it 'returns products associated with the selected taxons' do
              expect(assigns(:storefront_products).records).to eq([product3])
            end
          end

          context 'and product matches one taxon from each taxonomy' do
            let(:taxonomy_ids) { { taxonomy.id => { taxon_ids: [taxon.id, taxon2.id] }, taxonomy2.id => { taxon_ids: [taxon3.id, taxon4.id] } } }
            let(:taxon4) { create(:taxon, taxonomy: taxonomy2) }
            let(:product3) { create(:product, stores: [store], taxons: [taxon, taxon3]) }

            it 'returns products associated with the selected taxons' do
              expect(assigns(:storefront_products).records).to eq([product3])
            end
          end

          context 'and product matches three taxons from three taxonomies' do
            let(:taxonomy_ids) { { taxonomy.id => { taxon_ids: [taxon.id, taxon2.id] }, taxonomy2.id => { taxon_ids: [taxon3.id, taxon4.id] }, taxonomy3.id => { taxon_ids: [taxon5.id] } } }
            let(:taxonomy3) { create(:taxonomy) }
            let(:taxon4) { create(:taxon, taxonomy: taxonomy2) }
            let(:taxon5) { create(:taxon, taxonomy: taxonomy3) }
            let(:product3) { create(:product, stores: [store], taxons: [taxon, taxon3, taxon5]) }

            it 'returns products associated with the selected taxons' do
              expect(assigns(:storefront_products).records).to eq([product3])
            end
          end

          context 'and product matches taxon from parent' do
            let(:taxonomy_ids) { { taxonomy.id => { taxon_ids: [taxon.id, taxon2.id] }, taxonomy2.id => { taxon_ids: [taxon4.id] } } }
            let(:taxon3) { create(:taxon, taxonomy: taxonomy2, parent_id: taxon4.id) }
            let(:taxon4) { create(:taxon, taxonomy: taxonomy2) }
            let(:product3) { create(:product, stores: [store], taxons: [taxon, taxon3]) }

            it 'returns products associated with the selected taxons' do
              expect(assigns(:storefront_products).records).to eq([product3])
            end
          end
        end
      end
    end

    context 'when sorting by best selling' do
      let!(:product1) { create(:product, name: 'Running Jacket', stores: [store]) }
      let!(:product2) { create(:product, name: 'Waterproof Shoes', stores: [store]) }
      let!(:product3) { create(:product, name: 'Warming gloves', stores: [store]) }
      let!(:product4) { create(:product, name: 'Product out of stock', stores: [store]) }
      let!(:product6) { create(:product, name: 'Product for free', stores: [store]) }

      before do
        {
          product6 => { units_sold_count: 6, revenue: 60.0 },
          product2 => { units_sold_count: 5, revenue: 50.0 },
          product1 => { units_sold_count: 3, revenue: 30.0 },
          product3 => { units_sold_count: 3, revenue: 20.0 },
          product4 => { units_sold_count: 0, revenue: 0.0 }
        }.each do |product, metrics|
          Spree::StoreProduct.where(store_id: store.id, product_id: product.id).update_all(metrics)
        end
      end

      it 'orders products by units sold' do
        get :index, params: { sort_by: 'best-selling' }

        expect(assigns(:storefront_products).map(&:name)).to eq [
          product6.name,
          product2.name,
          product1.name,
          product3.name,
          product4.name
        ]
      end
    end
  end

  describe '#show' do
    subject { get :show, params: { id: product.slug, preview_id: preview_id } }

    shared_examples 'product not found' do
      it { expect { subject }.to raise_error(ActiveRecord::RecordNotFound) }
    end

    context 'when product is a draft' do
      before { product.update(status: :draft) }

      context 'when preview_id is specified' do
        let(:preview_id) { product.id }

        context 'when preview_id is valid' do
          it 'returns product page' do
            subject
            expect(response).to be_successful
          end
        end

        context 'when preview_id is not valid' do
          let(:preview_id) { 'wrong_id' }

          it_behaves_like 'product not found'
        end
      end

      context 'when preview_id is not specified' do
        it_behaves_like 'product not found'
      end
    end

    context 'when product is not a draft' do
      it 'returns product page' do
        subject
        expect(response).to be_successful
      end
    end

    context 'when product is not found' do
      before { product.destroy }

      it_behaves_like 'product not found'
    end
  end

  describe '#related' do
    subject { get :related, params: { id: product.slug, section_id: section.id } }
    let(:section) { store.default_theme.pages.product_details.first.sections.related_products.first }

    it 'responds successfully' do
      subject

      expect(response).to be_successful
    end
  end
end
