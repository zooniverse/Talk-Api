module Moderatable
  extend ActiveSupport::Concern

  included do
    has_one :moderation, as: :target
    class_attribute :moderatable
    self.moderatable = { }
    after_destroy :close_moderation
  end

  module ClassMethods
    def moderatable_with(action, by: [])
      self.moderatable = self.moderatable.merge action => { }
      by.each{ |role| self.moderatable[action][role] = true }
    end
  end

  def close_moderation
    return unless moderation && moderation.opened?
    moderation.state = 'closed'
    moderation.destroyed_target = as_json
    moderation.target = nil
    moderation.save
  end
end
