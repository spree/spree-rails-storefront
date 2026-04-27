require 'spec_helper'

describe Spree::Stores::Socials, type: :model do
  let(:store) { @default_store }

  describe '#facebook_link' do
    it 'returns the URL as-is when it starts with http://' do
      store.update!(facebook: 'http://facebook.com/spree')
      expect(store.facebook_link).to eq('http://facebook.com/spree')
    end

    it 'returns the URL as-is when it starts with https://' do
      store.update!(facebook: 'https://facebook.com/spree')
      expect(store.facebook_link).to eq('https://facebook.com/spree')
    end

    it 'is case-insensitive on the scheme' do
      store.update!(facebook: 'HTTPS://facebook.com/spree')
      expect(store.facebook_link).to eq('HTTPS://facebook.com/spree')
    end

    it 'substitutes a bare handle into the canonical profile URL' do
      store.update!(facebook: 'spree')
      expect(store.facebook_link).to eq('https://www.facebook.com/spree')
    end

    context 'with a non-http scheme' do
      it 'does not return a javascript: URL even when the value contains "http"' do
        store.update!(facebook: 'javascript:alert(1)//http')
        expect(store.facebook_link).not_to start_with('javascript:')
      end

      it 'does not return a data: URL even when the value contains "http"' do
        store.update!(facebook: 'data:text/html;http,<script>alert(1)</script>')
        expect(store.facebook_link).not_to start_with('data:')
      end

      it 'does not return a vbscript: URL even when the value contains "http"' do
        store.update!(facebook: 'vbscript:msgbox(1)//http')
        expect(store.facebook_link).not_to start_with('vbscript:')
      end
    end
  end
end
