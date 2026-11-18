module Matches
  # A head-to-head rule was broken. It is a kind of draft rule violation, so the
  # API's existing handler turns it into a 422 with the message.
  class RuleViolation < Drafts::RuleViolation; end
end
