class Discussion < ActiveRecord::Base
  include Moderatable
  
  belongs_to :user, required: true
  belongs_to :board, counter_cache: true
  has_many :comments
  
  validates :title, presence: true, length: 3..140
  
  before_create :denormalize_attributes
  before_destroy :clear_deleted_comments
  
  moderatable_with :destroy, by: [:moderator, :admin]
  moderatable_with :ignore, by: [:moderator, :admin]
  moderatable_with :report, by: [:all]
  moderatable_with :watch, by: [:moderator, :admin]
  
  def count_users!
    self.users_count = comments.select(:user_id).distinct.count
    save if changed?
  end
  
  protected
  
  def denormalize_attributes
    self.user_name = user.name
  end
  
  def clear_deleted_comments
    if comments.where(is_deleted: false).any?
      errors.add :comments, :'restrict_dependent_destroy.many', record: 'comments'
      false
    else
      comments.destroy_all
    end
  end
end
