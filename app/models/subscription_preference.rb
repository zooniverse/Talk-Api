class SubscriptionPreference < ActiveRecord::Base
  include SubscriptionCategories
  include BooleanCoercion
  belongs_to :user, required: true
  
  validates :enabled, inclusion: { in: [true, false] }
  scope :enabled, ->{ where enabled: true }
  after_update :unsubscribe_user, if: ->{ enabled_change == [true, false] }
  validates :email_digest, inclusion: {
    in: %w(immediate daily weekly never)
  }
  
  enum email_digest: {
    immediate: 0,
    daily: 1,
    weekly: 2,
    never: 3
  }
  
  def self.defaults
    {
      participating_discussions: :daily,
      mentions: :immediate,
      messages: :immediate,
      system: :immediate,
      followed_discussions: :daily,
      moderation_reports: :immediate,
      group_mentions: :immediate
    }.with_indifferent_access
  end
  
  def self.for_user(user)
    {
      participating_discussions: find_or_default_for(user, :participating_discussions),
      mentions: find_or_default_for(user, :mentions),
      messages: find_or_default_for(user, :messages),
      system: find_or_default_for(user, :system),
      followed_discussions: find_or_default_for(user, :followed_discussions),
      moderation_reports: find_or_default_for(user, :moderation_reports),
      group_mentions: find_or_default_for(user, :group_mentions),
    }
  end
  
  def self.find_or_default_for(user, category)
    where(user_id: user.id, category: categories[category]).first_or_create do |preference|
      preference.email_digest = email_digests[defaults[category]]
    end
  end
  
  def unsubscribe_user
    user.subscriptions.where(category: category).each do |subscription|
      subscription.update enabled: false
    end
  end
end
