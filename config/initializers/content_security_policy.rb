# Be sure to restart your server when you modify this file.
#
# Content Security Policy: the browser only runs code we serve ourselves.
# See https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.script_src :self # plus a per-request nonce for the admin importmap (below)
    # The spin reels set CSS custom properties through inline style attributes,
    # which nonces cannot cover. Inline styles can't run code, so they stay allowed.
    policy.style_src :self, :unsafe_inline
    policy.img_src :self, :data
    policy.font_src :self, :data
    policy.connect_src :self # the JSON API and the Action Cable WebSocket, same origin
    policy.object_src :none
    policy.base_uri :self
    policy.form_action :self
    policy.frame_ancestors :none # no clickjacking: the app can't be framed
  end

  # A fresh random nonce per request for inline scripts such as the importmap.
  config.content_security_policy_nonce_generator = ->(_request) { SecureRandom.base64(16) }
  config.content_security_policy_nonce_directives = %w[script-src]
end
