class DiscussionSerializer
  include TalkSerializer
  include ModerationActions
  
  all_attributes
  can_include :comments, :board, :user
  can_filter_by :sticky
  can_sort_by :updated_at, :sticky_position
  self.default_sort = '-updated_at,sticky_position'
end
