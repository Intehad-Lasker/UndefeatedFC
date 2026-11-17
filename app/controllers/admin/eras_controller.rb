module Admin
  # Adjust era names and date ranges. The model refuses overlaps, backed by the
  # GiST exclusion constraint, so a bad edit comes back as a form error.
  class ErasController < BaseController
    def index
      @eras = Era.ordered
    end

    def edit
      @era = Era.find(params[:id])
    end

    def update
      @era = Era.find(params[:id])
      if @era.update(params.expect(era: %i[name starts_on ends_on]))
        redirect_to admin_eras_path, notice: "Saved #{@era.label}."
      else
        render :edit, status: :unprocessable_content
      end
    end
  end
end
