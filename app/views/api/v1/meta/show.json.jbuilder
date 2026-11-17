json.skills Skills.all, :key, :label, :description
json.weight_classes @weight_classes, :id, :name, :limit_lbs
json.eras @eras, :id, :name, :label, :starts_on, :ends_on
json.rules do
  json.rounds Skills.all.size
  json.fights FightSimulator::FIGHTS
  json.min_choices Drafts::Spinner::MIN_CHOICES
end
