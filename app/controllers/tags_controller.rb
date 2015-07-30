class TagsController < ApplicationController
  include TalkResource
  
  def popular
    render json: popular_serializer.resource(params, nil, current_user: current_user)
  end
  
  def popular_serializer
    if params[:taggable_id] || params[:taggable_type]
      PopularFocusTagSerializer
    else
      PopularTagSerializer
    end
  end
end
