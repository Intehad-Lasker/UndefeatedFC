module Skills
  # A skill turns a fighter's stats into one raw number where higher is better.
  # The ratings engine ranks those numbers across all fighters, so a skill never
  # needs to know the scale of the others.
  #
  # Subclasses implement #description and #raw_score. The fighter passed in is
  # loaded with Fighter.with_ufc_record, so #ufc_record is available.
  class Base
    def key = self.class.name.demodulize.underscore
    def label = self.class.name.demodulize.titleize

    def description
      raise NotImplementedError, "#{self.class} must describe what it measures"
    end

    def raw_score(_fighter)
      raise NotImplementedError, "#{self.class} must implement raw_score"
    end
  end
end
