module Admin
  # Internal tools, rendered by Rails with Hotwire rather than React: they are
  # forms and tables for a handful of people, which Rails does with almost no
  # code. Sign-in comes from the generated session pages; only admins get in.
  class BaseController < ApplicationController
    layout "admin"

    before_action :require_admin

    private

    def require_admin
      # Explicit layout: Mission Control's controllers inherit this check but
      # use their own layout, which needs a running queue to render.
      render "admin/forbidden", layout: "admin", status: :forbidden unless Current.user&.admin?
    end
  end
end
