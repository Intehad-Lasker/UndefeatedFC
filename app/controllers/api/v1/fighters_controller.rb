module Api
  module V1
    # Fighter search and profiles. Ratings are not included: they are revealed
    # only through picks, so a player can't look them up mid-draft.
    class FightersController < BaseController
      SEARCH_LIMIT = 20
      RECENT_BOUTS = 10

      def index
        @fighters = Fighter.search(params[:q]).with_ufc_record.limit(SEARCH_LIMIT)
      end

      def show
        @fighter = Fighter.with_ufc_record.find(params[:id])
        return unless stale?(@fighter) # the scraper bumps updated_at whenever it reloads a fighter

        @appearances = Appearance.where(fighter: @fighter)
          .includes(bout: [ :event, :weight_class, { appearances: :fighter } ])
          .order("events.held_on DESC").references(:events)
          .limit(RECENT_BOUTS)
        @pools = Appearance.with_era.where(fighter: @fighter)
          .joins(bout: :weight_class)
          .distinct.order("eras.starts_on", "weight_classes.position")
          .pluck("weight_classes.name", "eras.name", "eras.starts_on", "weight_classes.position")
      end
    end
  end
end
