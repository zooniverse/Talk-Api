class User < ActiveRecord::Base
  include Moderatable
  
  has_many :roles
  has_many :user_conversations
  has_many :conversations, through: :user_conversations
  has_many :notifications
  has_many :subscriptions
  has_many :subscription_preferences
  has_many :blocked_users
  has_one :unsubscribe_token
  
  moderatable_with :ignore, by: [:moderator, :admin]
  moderatable_with :report, by: [:all]
  moderatable_with :watch, by: [:moderator, :admin]
  
  def self.from_panoptes(bearer_token)
    token = OauthAccessToken.find_by_token bearer_token
    token.resource_owner
  rescue
    nil
  end
  
  def mentioned_by(comment)
    subscription = subscribe_to comment.discussion, :mentions
    
    Notification.create({
      source: comment,
      user_id: id,
      message: "You were mentioned by #{ comment.user.display_name } in #{ comment.discussion.title }",
      url: FrontEnd.link_to(comment),
      section: comment.section,
      subscription: subscription
    }) if subscription.try(:enabled?)
  end
  
  def preference_for(category)
    SubscriptionPreference.find_or_default_for self, category
  end
  
  def subscribe_to(source, category)
    preference = preference_for category
    return unless preference.enabled?
    category = Subscription.categories[category]
    Subscription.where(user: self, category: category, source: source).first_or_create
  rescue
    nil
  end
  
  def unsubscribe_from(source, category = nil)
    query = { user: self, source: source }
    query[:category] = Subscription.categories[category] if category
    Subscription.where(query).update_all enabled: false
  end
end
