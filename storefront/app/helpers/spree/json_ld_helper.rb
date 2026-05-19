module Spree
  module JsonLdHelper
    # spree_api globally sets ActiveSupport::JSON::Encoding.escape_html_entities_in_json = false,
    # so a literal `</script>` in any field would break out of the surrounding script tag.
    # ERB::Util.json_escape post-processes the encoded JSON to escape `<`, `>`, `&` regardless
    # of that global flag.
    def json_ld_script(data, **html_attrs)
      json = ERB::Util.json_escape(data.to_json)
      content_tag(:script, json.html_safe, type: 'application/ld+json', **html_attrs)
    end
  end
end
