module Admin
  # Choose which divisions can come up on a spin. Changes apply to the next spin
  # (pool sizes are computed live) and change /api/v1/meta's ETag.
  class WeightClassesController < BaseController
    def index
      @weight_classes = WeightClass.ordered
      @bout_counts = Bout.group(:weight_class_id).count # one query, not one per row
    end

    def update
      weight_class = WeightClass.find(params[:id])
      weight_class.update!(spinnable: params.expect(weight_class: [ :spinnable ])[:spinnable])
      redirect_to admin_weight_classes_path, notice: "#{weight_class.name} is #{weight_class.spinnable? ? 'now' : 'no longer'} spinnable."
    end
  end
end
