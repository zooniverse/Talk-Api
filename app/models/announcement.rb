class Announcement < ActiveRecord::Base
  scope :expired, ->{ where 'expired_at < ?', Time.now.utc }
  before_create :assign_default_expiration
  after_create :publish
  
  protected
  
  def assign_default_expiration
    self.expires_at ||= 1.month.from_now.utc
  end
  
  def publish
    AnnouncementWorker.perform_async id
  end
end