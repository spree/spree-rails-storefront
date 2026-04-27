require 'spec_helper'

RSpec.describe Spree::JsonLdHelper, type: :helper do
  describe '#json_ld_script' do
    let(:malicious) { '</script><script>alert(1)</script>' }

    around do |example|
      original = ActiveSupport::JSON::Encoding.escape_html_entities_in_json
      ActiveSupport::JSON::Encoding.escape_html_entities_in_json = false
      example.run
      ActiveSupport::JSON::Encoding.escape_html_entities_in_json = original
    end

    it 'escapes </script> in string values regardless of the global JSON HTML-escape flag' do
      output = helper.json_ld_script({ 'name' => malicious })
      expect(output).not_to include('</script><script>')
      expect(output).to include('\u003c/script\u003e\u003cscript\u003e')
    end

    it 'wraps payload in a script tag with application/ld+json type' do
      output = helper.json_ld_script({ 'name' => 'Acme' })
      expect(output).to start_with('<script type="application/ld+json">')
      expect(output).to end_with('</script>')
    end

    it 'forwards arbitrary HTML attributes' do
      output = helper.json_ld_script({}, data: { test_id: 'product-json-ld' })
      expect(output).to include('data-test-id="product-json-ld"')
    end

    it 'recursively escapes inside nested hashes and arrays' do
      output = helper.json_ld_script({
        'breadcrumbs' => [{ 'name' => malicious }]
      })
      expect(output).not_to include('</script><script>')
    end
  end
end
