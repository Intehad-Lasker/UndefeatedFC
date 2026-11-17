module Skills
  # Durability: the share of UFC fights that did not end in a KO/TKO loss. Most
  # fighters have never been stopped, so many tie at 1.0; the ratings engine
  # breaks those ties by trusting longer careers more (see Ratings::Normalizer).
  class Chin < Base
    def description = "Share of UFC fights not lost by knockout"

    def raw_score(fighter)
      1.0 - fighter.ufc_record.ko_loss_rate
    end
  end
end
