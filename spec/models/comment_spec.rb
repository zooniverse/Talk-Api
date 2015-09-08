require 'spec_helper'

RSpec.describe Comment, type: :model do
  it_behaves_like 'a notifiable model'
  it_behaves_like 'a sectioned model'
  it_behaves_like 'moderatable'
  it_behaves_like 'a searchable interface'
  it_behaves_like 'a searchable model' do
    let(:searchable_board){ create :board }
    let(:searchable_discussion){ create :discussion, board: searchable_board }
    let(:searchable){ create :comment, discussion: searchable_discussion }
    
    let(:unsearchable_board){ create :board, permissions: { read: 'admin' } }
    let(:unsearchable_discussion){ create :discussion, board: unsearchable_board }
    let(:unsearchable){ create :comment, discussion: unsearchable_discussion }
  end
  
  context 'validating' do
    it 'should require a body' do
      without_body = build :comment, body: nil
      expect(without_body).to fail_validation body: "can't be blank"
    end
    
    it 'should require a user' do
      without_user = build :comment, user_id: nil
      expect(without_user).to fail_validation user: "can't be blank"
    end
    
    it 'should require a section' do
      without_section = build :comment, section: nil
      allow(without_section).to receive :set_section
      expect(without_section).to fail_validation section: "can't be blank"
    end
    
    context 'requiring a focus_type' do
      context 'when focus_id is blank' do
        it 'should permit a blank focus_type' do
          without_focus_type = build :comment, focus_id: nil, focus_type: nil
          expect(without_focus_type).to be_valid
        end
      end
      
      context 'when focus_id is present' do
        it 'should not permit a blank focus_type' do
          without_focus_type = build :comment, focus_id: create(:subject).id, focus_type: nil
          expect(without_focus_type).to fail_validation focus_type: 'must be "Subject" or "Collection"'
        end
      end
    end
  end
  
  context 'creating' do
    it 'should set default attributes' do
      comment = create :comment
      expect(comment.tagging).to eql({ })
      expect(comment.is_deleted).to be false
    end
    
    it 'should set the section' do
      comment = build :comment, section: nil
      expect{
        comment.validate
      }.to change{
        comment.section
      }.to comment.discussion.section
    end
    
    it 'should denormalize the user login' do
      comment = create :comment
      expect(comment.user_login).to eql comment.user.login
    end
    
    it 'should denormalize the focus type for focuses' do
      subject_comment = create :comment, focus: build(:subject)
      expect(subject_comment.focus_type).to eql 'Subject'
    end
    
    it 'should denormalize the board id' do
      comment = create :comment
      expect(comment.board_id).to eql comment.discussion.board.id
    end
    
    it 'should update the discussion comment count' do
      discussion = create :discussion
      expect {
        create :comment, discussion: discussion
      }.to change {
        discussion.reload.comments_count
      }.by 1
    end
    
    it 'should update the discussion updated_at timestamp' do
      discussion = create :discussion
      expect {
        create :comment, discussion: discussion
      }.to change {
        discussion.reload.updated_at
      }
    end
    
    it 'should update the discussion user count' do
      discussion = create :discussion
      expect {
        comment = create :comment, discussion: discussion
        create_list :comment, 2, discussion: discussion
        create :comment, discussion: discussion, user: comment.user
      }.to change {
        discussion.reload.users_count
      }.by 3
    end
    
    context 'destroying' do
      let(:subject){ create :subject }
      let(:comment){ create :comment, body: "#tag, ^S#{ subject.id }" }
      
      it 'should destroy tags' do
        tag = comment.tags.first
        comment.destroy
        expect{ tag.reload }.to raise_error ActiveRecord::RecordNotFound
      end
      
      it 'should destroy mentions' do
        mention = comment.mentions.first
        comment.destroy
        expect{ mention.reload }.to raise_error ActiveRecord::RecordNotFound
      end
      
      it 'should remove reply references' do
        reply = create :comment, reply: comment
        expect{
          comment.destroy
        }.to change{
          reply.reload.reply
        }.from(comment).to nil
      end
    end
    
    describe '#soft_destroy' do
      let(:subject){ create :subject }
      let(:comment){ create :comment, body: "#tag, ^S#{ subject.id }" }
      let!(:other){ create :comment, discussion: comment.discussion }
      
      it 'should destroy tags' do
        tag = comment.tags.first
        comment.soft_destroy
        expect{ tag.reload }.to raise_error ActiveRecord::RecordNotFound
      end
      
      it 'should destroy mentions' do
        mention = comment.mentions.first
        comment.soft_destroy
        expect{ mention.reload }.to raise_error ActiveRecord::RecordNotFound
      end
      
      it 'should not destroy the comment' do
        comment.soft_destroy
        expect{ comment.reload }.to_not raise_error
      end
      
      it 'should mark the comment as destroyed' do
        comment.soft_destroy
        expect(comment.is_deleted?).to be true
      end
      
      it 'should close the moderation' do
        expect(comment).to receive :close_moderation
        comment.soft_destroy
      end
      
      it 'should clear the comment body' do
        comment.soft_destroy
        expect(comment.body).to eql 'This comment has been deleted'
      end
      
      it 'should destroy discussions when empty' do
        other.soft_destroy
        comment.soft_destroy
        expect{ comment.discussion.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
    
    context 'updating board counts' do
      let(:board) do
        discussion1 = create :discussion_with_comments, comment_count: 3, user_count: 2
        board = discussion1.board
        discussion2 = create :discussion_with_comments, board: board, comment_count: 3, user_count: 2
        board
      end
      
      it 'should update the comment count' do
        expect(board.comments_count).to eql 6
      end
      
      it 'should update the user count' do
        expect(board.users_count).to eql 4
      end
    end
  end
  
  context 'when moving discussions' do
    let!(:source){ create :discussion }
    let!(:destination){ create :discussion }
    let!(:comment){ create :comment, discussion: source }
    
    def move_comment
      Comment.find(comment.id).update! discussion_id: destination.id
    end
    
    it 'should update the source users_count' do
      expect{ move_comment }.to change{ source.reload.users_count }.by -1
    end
    
    it 'should update the source comments_count' do
      expect{ move_comment }.to change{ source.reload.comments_count }.from(1).to 0
    end
    
    it 'should update the source board comments_counts' do
      expect{ move_comment }.to change{ source.board.reload.comments_count }.from(1).to 0
    end
    
    it 'should update the source board users_counts' do
      expect{ move_comment }.to change{ source.board.reload.users_count }.from(1).to 0
    end
    
    it 'should update the destination users_count' do
      expect{ move_comment }.to change{ destination.reload.users_count }.from(0).to 1
    end
    
    it 'should update the destination comments_count' do
      expect{ move_comment }.to change{ destination.reload.comments_count }.from(0).to 1
    end
    
    it 'should update the destination board comments_counts' do
      expect{ move_comment }.to change{ destination.board.reload.comments_count }.from(0).to 1
    end
    
    it 'should update the destination board users_counts' do
      expect{ move_comment }.to change{ destination.board.reload.users_count }.from(0).to 1
    end
  end
  
  describe '#parse_mentions' do
    let(:subject){ create :subject }
    let(:subject_mention){ "^S#{ subject.id }" }
    
    let(:collection){ create :collection }
    let(:collection_mention){ "^C#{ collection.id }" }
    
    let(:user){ create :user }
    let(:user_mention){ "@#{ user.login }" }
    let(:admin_user){ create :admin, section: 'zooniverse' }
    
    let(:board){ create :board }
    let(:discussion){ create :discussion, board: board }
    
    let(:body){ "#{ subject_mention } should be added to #{ collection_mention }, right @#{ user.login }?" }
    let(:comment){ create :comment, discussion: discussion, body: body }
    
    it 'should match subjects' do
      expect(comment.mentioning).to include subject_mention => {
        'id' => subject.id, 'type' => 'Subject'
      }
    end
    
    it 'should match collections' do
      expect(comment.mentioning).to include collection_mention => {
        'id' => collection.id, 'type' => 'Collection'
      }
    end
    
    it 'should match users' do
      expect(comment.mentioning).to include user_mention => {
        'id' => user.id, 'type' => 'User'
      }
    end
    
    it 'should create mentions for subjects' do
      expect(comment.mentions.where(mentionable: subject).exists?).to be true
    end
    
    it 'should create mentions for collections' do
      expect(comment.mentions.where(mentionable: collection).exists?).to be true
    end
    
    it 'should create mentions for users' do
      expect(comment.mentions.where(mentionable: user).exists?).to be true
    end
    
    context 'when the comment is not accessible by the mentioned user' do
      let(:body){ "Hey @#{ user.login } and @#{ admin_user.login }" }
      let(:board){ create :board, permissions: { read: 'team', write: 'team' } }
      
      it 'should not create mentions for users without access' do
        expect(comment.mentions.where(mentionable: user).exists?).to be false
      end
      
      it 'should create mentions for users with access' do
        expect(comment.mentions.where(mentionable: admin_user).exists?).to be true
      end
    end
  end
  
  describe '#update_mentions' do
    let(:subject){ create :subject }
    let(:subject_mention){ "^S#{ subject.id }" }
    let(:collection){ create :collection }
    let(:collection_mention){ "^C#{ collection.id }" }
    let(:comment){ create :comment, body: "#{ subject_mention } #{ collection_mention }" }
    
    it 'should remove mentions on update' do
      comment.update! body: subject_mention
      expect(comment.mentions.where(mentionable: collection).exists?).to be false
    end
    
    it 'should add mentions on update' do
      subject2 = create :subject
      comment.update! body: "#{ comment.body } ^S#{ subject2.id }"
      expect(comment.mentions.where(mentionable: subject2).exists?).to be true
    end
  end
  
  describe '#parse_tags' do
    let(:comment){ create :comment, body: '#tag1 not#atag #Tag' }
    
    it 'should match tags' do
      expect(comment.tagging).to eql '#tag1' => 'tag1', '#Tag' => 'tag'
    end
    
    it 'should create tags' do
      expect(comment.tags.where(name: 'tag1').exists?).to be true
      expect(comment.tags.where(name: 'tag').exists?).to be true
      expect(comment.tags.count).to eql 2
    end
  end
  
  describe '#upvote!' do
    let(:comment){ create :comment, upvotes: { somebody: 1234 } }
    let(:voter){ create :user }
    
    it 'should add the user login' do
      expect {
        comment.upvote! voter
      }.to change {
        comment.reload.upvotes.keys
      }.from(['somebody']).to match_array ['somebody', voter.login]
    end
  end
  
  describe '#remove_upvote!' do
    let(:comment){ create :comment, upvotes: { somebody: 1234, somebody_else: 4567 } }
    let(:voter){ create :user, login: 'somebody' }
    
    it 'should remove the user login' do
      expect {
        comment.remove_upvote! voter
      }.to change {
        comment.reload.upvotes.keys
      }.from(['somebody', 'somebody_else']).to match_array ['somebody_else']
    end
  end
  
  describe '#subscribe_user' do
    let(:commenting_user){ create :user }
    let(:discussion){ create :discussion }
    let(:subscriber){ create :subscription, source: discussion, category: :participating_discussions }
    let(:subscription){ commenting_user.subscriptions.participating_discussions.where source: discussion }
    let(:comment){ create :comment, discussion: discussion, user: commenting_user }
    
    it 'should subscribe commenting users' do
      comment
      expect(subscription.exists?).to be true
    end
    
    context 'when preference is disabled' do
      before(:each) do
        commenting_user.preference_for(:participating_discussions).update_attributes enabled: false
      end
      
      it 'should not subscribe the user' do
        comment
        expect(subscription.exists?).to be false
      end
    end
  end
  
  describe '#notify_subscribers_later' do
    let(:comment){ create :comment }
    
    it 'should queue the notification' do
      expect(CommentSubscriptionWorker).to receive(:perform_async).with comment.id
      comment.run_callbacks :commit
    end
  end
  
  describe '#notify_subscribers' do
    let(:participating_users){ create_list :user, 2 }
    let(:following_user){ create :user }
    let(:users){ participating_users + [following_user] }
    let(:notified_users){ Notification.all.collect &:user }
    let(:unsubscribed_user){ create :user }
    let(:discussion){ create :discussion }
    
    before(:each) do
      participating_users.each{ |user| user.subscribe_to discussion, :participating_discussions }
      following_user.subscribe_to discussion, :followed_discussions
      unsubscribed_user.preference_for(:participating_discussions).update_attributes enabled: false
    end
    
    it 'should create notifications for subscribed users' do
      comment = create :comment, discussion: discussion
      comment.notify_subscribers
      expect(notified_users).to match_array users
    end
    
    it 'should not create notifications for unsubscribed users' do
      comment = create :comment, discussion: discussion
      comment.notify_subscribers
      expect(notified_users).to_not include unsubscribed_user
    end
    
    it 'should not create a notification for the commenting user' do
      user = users.first
      comment = create :comment, discussion: discussion, user: user
      comment.notify_subscribers
      expect(user.notifications).to be_empty
    end
  end
  
  describe '#subscriptions_to_notify' do
    let(:discussion){ create :discussion }
    let(:comment){ create :comment, discussion: discussion, user: user1 }
    let(:user1){ create :user }
    let(:user2){ create :user }
    let(:user3){ create :user }
    let!(:participating1){ create :subscription, category: :participating_discussions, source: discussion, user: user1, enabled: true }
    let!(:participating2){ create :subscription, category: :participating_discussions, source: discussion, user: user2, enabled: false }
    let!(:participating3){ create :subscription, category: :participating_discussions, source: discussion, user: user3, enabled: false }
    let!(:following1){ create :subscription, category: :followed_discussions, source: discussion, user: user1, enabled: true }
    let!(:following2){ create :subscription, category: :followed_discussions, source: discussion, user: user2, enabled: true }
    let!(:following3){ create :subscription, category: :followed_discussions, source: discussion, user: user3, enabled: false }
    subject{ comment.subscriptions_to_notify }
    its(:length){ is_expected.to eql 1 }
    its('first.user_id'){ is_expected.to eql user2.id }
  end
  
  describe '#searchable?' do
    subject{ create :comment }
    
    context 'when the discussion is searchable' do
      before(:each){ allow(subject.discussion).to receive(:searchable?).and_return true }
      
      context 'when the comment is not deleted' do
        before(:each){ subject.is_deleted = false }
        it{ is_expected.to be_searchable }
      end
      
      context 'when the comment is deleted' do
        before(:each){ subject.is_deleted = true }
        it{ is_expected.to_not be_searchable }
      end
    end
    
    context 'when the discussion is not searchable' do
      before(:each){ allow(subject.discussion).to receive(:searchable?).and_return false }
      
      context 'when the comment is not deleted' do
        before(:each){ subject.is_deleted = false }
        it{ is_expected.to_not be_searchable }
      end
      
      context 'when the comment is deleted' do
        before(:each){ subject.is_deleted = true }
        it{ is_expected.to_not be_searchable }
      end
    end
  end
end
