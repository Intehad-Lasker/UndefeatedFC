module Admin
  # Fix scraped fighter data. Each row is a Turbo Frame: Edit swaps the row for
  # a form and Save swaps it back, without a page reload or custom JavaScript.
  class FightersController < BaseController
    PER_PAGE = 50
    EDITABLE = %i[name nickname stance height_cm reach_cm locked].freeze

    before_action :set_fighter, only: %i[show edit update]

    def index
      @query = params[:q].to_s.strip
      @page = [ params[:page].to_i, 1 ].max
      scope = @query.present? ? Fighter.search(@query) : Fighter.order(:name)
      @fighters = scope.offset((@page - 1) * PER_PAGE).limit(PER_PAGE + 1).to_a
      @next_page = @fighters.size > PER_PAGE
      @fighters = @fighters.first(PER_PAGE)
    end

    def show
      render partial: "fighter", locals: { fighter: @fighter }
    end

    def edit
    end

    def update
      if @fighter.update(params.expect(fighter: EDITABLE))
        render partial: "fighter", locals: { fighter: @fighter }
      else
        render :edit, status: :unprocessable_content
      end
    end

    private

    def set_fighter
      @fighter = Fighter.find(params[:id])
    end
  end
end
