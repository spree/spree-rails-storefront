require 'spec_helper'

RSpec.describe Spree::ColorsPreviewStylesPresenter do
  describe '#to_s' do
    it 'emits CSS rules for recognised color names' do
      output = described_class.new(['Red']).to_s
      expect(output).to include('<style>')
      expect(output).to include('.color-input[value="Red"]')
      expect(output).to include('background:')
    end

    it 'omits the rule entirely when the name is not a recognised color' do
      output = described_class.new(['Definitely Not A Color']).to_s
      expect(output).to be_nil
    end

    context 'with a malicious color name' do
      let(:payload) { %q(Red"]{}</style><script>alert(1)</script>) }

      it 'does not break out of the <style> block' do
        output = described_class.new([payload]).to_s.to_s
        expect(output).not_to include('</style>')
        expect(output).not_to include('<script>')
      end
    end

    context 'with a malicious filter name' do
      it 'does not allow CSS-context injection via the background value' do
        output = described_class.new([{ name: 'Red', filter_name: 'red;}body{display:none' }]).to_s
        # We do not emit rules for filter_names that contain CSS-unsafe chars,
        # so the malicious filter_name produces no output for this color.
        expect(output.to_s).not_to include('display:none')
        expect(output.to_s).not_to include('body{')
      end
    end
  end
end
