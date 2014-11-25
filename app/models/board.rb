class Board < ActiveRecord::Base
  has_many :discussions, dependent: :restrict_with_error
  has_many :comments, through: :discussions
  has_many :users, through: :comments
  
  validates :title, presence: true
  validates :description, presence: true
  
  def count_users_and_comments!
    self.comments_count = comments.count
    self.users_count = users.select(:id).distinct.count
    save if changed?
  end
end
