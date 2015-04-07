require 'spec_helper'

RSpec.describe Moderation, type: :model do
  context 'validating' do
    it 'should require a target' do
      without_target = build :moderation, target: nil
      expect(without_target).to fail_validation target: "can't be blank"
    end
    
    it 'should require a section' do
      without_section = build :moderation, section: nil
      expect(without_section).to fail_validation section: "can't be blank"
    end
  end
  
  context 'initializing' do
    it 'should accept a polymorphic target' do
      user = create :user
      moderation = create :moderation, target: user
      expect(moderation.target_id).to eql user.id
      expect(moderation.target_type).to eql 'User'
    end
  end
  
  context 'with state' do
    it 'should be opened by default' do
      moderation = create :moderation
      expect(moderation).to be_opened
    end
    
    it 'should update actioned_at when actioning' do
      moderation = create :moderation
      moderator = create :moderator
      expect {
        moderation.actions << {
          user_id: moderator.id,
          message: 'closing',
          state: 'closed'
        }
        moderation.save
      }.to change {
        moderation.actioned_at
      }
    end
  end
end
