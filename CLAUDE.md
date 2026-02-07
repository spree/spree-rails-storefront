# Claude Code Rules for Spree Rails Storefront Development

## Repository Structure

This repository contains two Rails engine gems:
- **storefront/** (`spree_storefront`) — Rails storefront with views, controllers, helpers
- **page_builder/** (`spree_page_builder`) — Visual page builder with models, admin UI, themes

Both gems depend on `spree_core` and `spree_admin` from the main [Spree](https://github.com/spree/spree) repository.

## General Development Guidelines

### Framework & Architecture

- Spree is built on Ruby on Rails and follows MVC architecture
- All Spree code must be namespaced under `Spree::` module
- Follow Rails conventions and the Rails Security Guide
- Prefer Rails idioms and standard patterns over custom solutions

### Code Organization

- Place all models in `app/models/spree/` directory
- Place all controllers in `app/controllers/spree/` directory
- Place all views in `app/views/spree/` directory
- Place all helpers in `app/helpers/spree/` directory
- Place all jobs in `app/jobs/spree/` directory
- Place all presenters in `app/presenters/spree/` directory
- Use consistent file naming: `spree/product.rb` for `Spree::Product` class
- Group related functionality into concerns when appropriate
- Do not call `Spree::User` directly, use `Spree.user_class` instead
- Do not call `Spree::AdminUser` directly, use `Spree.admin_user_class` instead

## Naming Conventions & Structure

### Classes & Modules

```ruby
# ✅ Correct naming
module Spree
  class Product < Spree.base_class
  end
end

module Spree
  module Admin
    class ProductsController < ResourceController
    end
  end
end

# ❌ Incorrect - missing namespace
class Product < ApplicationRecord
end
```

Always inherit from `Spree.base_class` when creating models.

### File Paths

- Models: `app/models/spree/page.rb`
- Controllers: `app/controllers/spree/admin/pages_controller.rb`
- Views: `app/views/spree/admin/pages/`
- Decorators: `app/models/spree/page_builder/store_decorator.rb`

## Storefront Development

### Controller Inheritance

- Storefront controllers inherit from `Spree::StoreController`
- Admin controllers (page_builder) inherit from `Spree::Admin::ResourceController`

### Frontend Stack

- **Tailwind CSS v4** — Responsive, mobile-first design
- **Turbo / Hotwire** — Fast, SPA-like navigation
- **StimulusJS** — JavaScript controllers for interactivity
- **Importmaps** — No Node.js required

### Views & Templates

- Page section partials live in `storefront/app/views/themes/default/spree/page_sections/`
- Use `render_page(current_page)` to render page builder pages
- Use `render_section(section)` to render individual sections
- Use `page_builder_enabled?` to check if in preview/edit mode
- Use `cache_unless page_builder_enabled?` to skip caching in edit mode

### Helpers

- `storefront/app/helpers/spree/page_helper.rb` — Page/section rendering logic
- `storefront/app/helpers/spree/theme_helper.rb` — Theme data access, preview support

## Page Builder Development

### Models

Key models (all in `page_builder/app/models/spree/`):
- `Spree::Page` — Represents a page (14 types: Homepage, Cart, ProductDetails, etc.)
- `Spree::Theme` — Theme management with multiple themes per store
- `Spree::PageSection` — Sections within a page (23 types)
- `Spree::PageBlock` — Blocks within a section (16+ types)
- `Spree::PageLink` — Navigation links within blocks

### Decorators

Page builder extends core models via decorators in `page_builder/app/models/spree/page_builder/`:
- `store_decorator.rb` — Adds page/theme associations to `Spree::Store`
- `product_decorator.rb` — Adds `Spree::Linkable` to `Spree::Product`
- `taxon_decorator.rb` — Adds `Spree::Linkable` to `Spree::Taxon`
- `policy_decorator.rb` — Adds `Spree::Linkable` to `Spree::Policy`

### Extensibility

Page builder provides registries for custom components:
```ruby
Spree.themes           # Register custom themes
Spree.pages            # Register custom page types
Spree.page_sections    # Register custom section types
Spree.page_blocks      # Register custom block types
```

### Admin Navigation

Register navigation items in `page_builder/config/initializers/spree_admin_navigation.rb`.

## Model Development

### Model Patterns

- Use ActiveRecord associations appropriately, always pass `class_name` and `dependent` options
- Implement concerns for shared functionality
- Use scopes for reusable query patterns
- Don't use enums, use string columns instead
- Don't ever cast IDs to integer, we need to support also UUIDs so please always treat IDs as strings

For uniqueness validation, always use `scope: spree_base_uniqueness_scope`

## Database & Migrations

### Migration Patterns

- Follow Rails migration conventions
- Use proper indexing for performance
- Do not include foreign key constraints
- Try to limit number of migrations to 1 per feature
- Always add `null: false` to required columns
- By default add `deleted_at` column to all tables that have soft delete functionality (we use `paranoia` gem)
- For migrations please use 7.2 as the target version as we still support Rails 7.2
- All page_builder migrations live in `page_builder/db/migrate/`
- Storefront has no migrations (uses page_builder tables)

## Testing

Always run tests before committing changes. Always run tests after making changes.

### Test Application

To run tests you need to create test app with `bundle exec rake test_app` in each gem directory.

This will create a dummy Rails application and run migrations. If there's already a dummy app in the gem directory, you can skip this step.

### Test Structure

- Use RSpec for testing and Factory Bot for creating test data
- As much as you can use `build` vs `create` for factories to speed up tests
- Be very pragmatic, don't over-engineer tests, don't repeat same tests in multiple places
- For controller specs always add `render_views` to the test
- For controller spec authentication use `stub_authorization!`
- Don't create test scenarios for standard Rails validation, only for custom validations
- For time-based testing use `Timecop` gem

```ruby
# Run storefront tests
cd storefront && bundle exec rake test_app && bundle exec rspec

# Run page_builder tests
cd page_builder && bundle exec rake test_app && bundle exec rspec
```

## Security

- Follow Rails Security Guide principles
- Implement proper authorization checks with CanCanCan
- Validate all user inputs
- Never permit mass assignment without validation
- Use allowlists, not blocklists for parameters

## Performance

- We're using `ar_lazy_preload` gem to avoid N+1 queries, also use `includes`/`preload`
- Use Rails caching mechanisms via `Rails.cache`
- Consider fragment caching for views
- Use `cache_key_with_version` when constructing custom cache keys

## Routes

- Always use `spree.` routes engine when using routes in views and controllers

## Internationalization

- Use `Spree.t` for translations
- Keep storefront translations in `storefront/config/locales/en.yml`
- Keep page_builder admin translations in `page_builder/config/locales/en.yml` (if applicable)
- Do not repeat translations in multiple files

## Version Management

- Both gems share a version defined in `lib/spree_storefront/version.rb`
- Update `SpreeStorefront::VERSION` when releasing
