class NotificationSerializer
  include TalkSerializer
  include EmbeddedAttributes
  
  all_attributes
  can_sort_by :created_at
  can_filter_by :section, :delivered
  can_include :subscription
  self.default_sort = 'created_at'
  self.eager_loads = [:project]
  
  def custom_attributes
    super.merge attributes_from :project
  end
end
