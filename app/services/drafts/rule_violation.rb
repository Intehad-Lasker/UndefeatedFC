module Drafts
  # Raised when a request breaks a game rule (spinning twice, picking a fighter
  # from another pool, ...). The message is written for players; the API
  # returns it with a 422.
  class RuleViolation < StandardError; end
end
