class Collection < ActiveRecord::Base
  self.table_name = 'collections'
  
  include Focusable
  belongs_to :project
  
  moderatable_with :destroy, by: [:moderator, :admin]
  moderatable_with :ignore, by: [:moderator, :admin]
  moderatable_with :report, by: [:all]
  moderatable_with :watch, by: [:moderator, :admin]
end
