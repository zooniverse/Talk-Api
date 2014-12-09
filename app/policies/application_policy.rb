class ApplicationPolicy
  attr_reader :user, :record
  
  def initialize(user, record)
    @user = user
    @record = record
  end
  
  def index?
    true
  end
  
  def show?
    true
  end
  
  def create?
    false
  end
  
  def update?
    false
  end
  
  def destroy?
    false
  end
  
  concerning :UserPredicates do
    def logged_in?
      !!user
    end
    
    def owner?
      logged_in? && user.id == record.user_id
    end
    
    # TO-DO: refactor to use an ALL query
    def participant?
      return false unless logged_in?
      Array.wrap(record).each do |record|
        return false unless record.users.exists?(id: user.id)
      end
      true
    end
    
    def moderator?
      logged_in? && 'moderator'.in?(user_roles)
    end
    
    def admin?
      logged_in? && 'admin'.in?(user_roles)
    end
    
    def user_roles
      (section_roles + zooniverse_roles).uniq
    end
    
    def section_roles
      return [] unless logged_in? && record.respond_to?(:section)
      user.roles.fetch record.section, []
    end
    
    def zooniverse_roles
      return [] unless logged_in?
      user.roles.fetch 'zooniverse', []
    end
  end
  
  def scope
    Pundit.policy_scope!(user, record.class)
  end
  
  class Scope
    include UserPredicates
    attr_reader :user, :scope
    
    def initialize(user, scope)
      @user = user
      @scope = scope
    end
    
    def resolve
      scope
    end
  end
end
