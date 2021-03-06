module Focusable
  extend ActiveSupport::Concern

  included do
    include Moderatable
    has_many :mentions, as: :mentionable, dependent: :destroy
    has_many :comments, as: :focus
    belongs_to :user

    validates :section, presence: true

    moderatable_with :ignore, by: [:moderator, :admin]
    moderatable_with :report, by: [:all]
  end

  def section
    if self.respond_to?(:project_ids) && self.project_ids
      project_ids.collect{ |project_id| "project-#{ project_id }" }
    else
      "project-#{ project.id }"
    end
  end

  def mentioned_by(comment)
    # Nobody to notify, really. Best we could do is notify whoever uploaded the subject
    # when it gets mentioned, but that doesn't seem right.
  end
end
