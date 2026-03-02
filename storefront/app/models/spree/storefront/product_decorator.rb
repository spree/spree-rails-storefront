module Spree
  module Storefront
    module ProductDecorator
      def self.prepended(base)
        # Override by_best_selling scope to use LEFT JOIN instead of correlated subqueries
        # for PostgreSQL compatibility with DISTINCT (PG requires ORDER BY expressions
        # to appear in the SELECT list when using DISTINCT)
        base.add_search_scope :by_best_selling do |order_direction = :desc|
          store_id = Spree::Current.store&.id
          order_dir = order_direction == :desc ? 'DESC' : 'ASC'

          joins(
            "LEFT JOIN spree_products_stores ON spree_products_stores.product_id = spree_products.id AND spree_products_stores.store_id = #{store_id.to_i}"
          ).
            select("spree_products.*, COALESCE(spree_products_stores.units_sold_count, 0) AS best_selling_units, COALESCE(spree_products_stores.revenue, 0) AS best_selling_revenue").
            order(Arel.sql("best_selling_units #{order_dir}, best_selling_revenue #{order_dir}"))
        end
      end
    end
  end
end

Spree::Product.prepend(Spree::Storefront::ProductDecorator)
