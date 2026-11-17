# Serves the React app's index.html for every page route (/, /drafts/:id, ...).
# React Router takes over in the browser; the JSON API stays under /api.
class SpaController < ActionController::Base
  class_attribute :index_path, default: Rails.public_path.join("app/index.html")

  def show
    if File.exist?(index_path)
      # Revalidate on every visit so a deploy's new asset hashes load at once.
      response.headers["Cache-Control"] = "no-cache"
      render file: index_path, layout: false, content_type: "text/html"
    else
      render plain: "The React app is not built. Run `npm run build` in web/, or use the Vite dev server at http://localhost:5173.",
        status: :service_unavailable
    end
  end
end
