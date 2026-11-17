module Api
  module V1
    # Game configuration the frontend needs: the skill slots, the spinnable
    # weight classes and eras, and the rules. Serving it means the UI never
    # hard-codes a list that lives in Ruby.
    class MetaController < BaseController
      def show
        @weight_classes = WeightClass.spinnable.ordered
        @eras = Era.ordered
        # Same for every visitor, so shared caches may store it.
        fresh_when(etag: [ @weight_classes, @eras, Skills.keys ], public: true)
      end
    end
  end
end
