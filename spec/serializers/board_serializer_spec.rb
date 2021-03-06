require 'spec_helper'

RSpec.describe BoardSerializer, type: :serializer do
  it_behaves_like 'a talk serializer', exposing: :all do
    let(:parent){ create :board }
    let(:model_instance){ create :board_with_subboards, parent: parent }
    it_behaves_like 'a serializer with embedded attributes', relations: [:project]
  end
end
