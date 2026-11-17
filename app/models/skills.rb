# The skill slots a draft fills. This list is the single source of truth: the
# ratings engine, the draft rules and the API all read it, so adding a skill is
# one new class plus one line here.
module Skills
  class UnknownSkill < ArgumentError; end

  ALL = [
    Striking.new,
    Power.new,
    Wrestling.new,
    Submissions.new,
    Defense.new,
    Chin.new
  ].freeze

  def self.all = ALL
  def self.keys = ALL.map(&:key)

  def self.find(key)
    ALL.find { |skill| skill.key == key.to_s } or raise UnknownSkill, "unknown skill: #{key}"
  end
end
