describe ActiveGraph::Relationship::RelatedNode do
  class RelatedNode < ActiveGraph::Relationship::RelatedNode; end

  before { allow_any_instance_of(RelatedNode).to receive(:call) }

  let(:node1) { ActiveGraph::Base.write_transaction { ActiveGraph::Base.query('CREATE (n) RETURN n').single.first } }
  let(:id) { node1.id }
  let(:rel) { double('Relationship object') }

  describe 'initialize' do
    it 'can be called without params' do
      expect { RelatedNode.new }.not_to raise_error
    end
  end

  context 'initialized with a node id' do
    let!(:r) { RelatedNode.new(id) }

    it 'sets @node' do
      expect(r.instance_variable_get(:@node)).to eq id
    end

    describe 'loaded' do
      it 'loads the node from the server if not loaded' do
        expect_queries(1) do
          r.loaded
        end
      end

      context 'with @node unset' do
        let(:r) { RelatedNode.new(nil) }

        it 'raises' do
          expect { r.loaded }.to raise_error ActiveGraph::Relationship::RelatedNode::UnsetRelatedNodeError
        end
      end
    end

    describe 'loaded?' do
      it 'returns false' do
        expect(r.loaded?).to be_falsey
      end
    end

    describe '==' do
      it 'loads the node and compares' do
        r.instance_variable_set('@node', node1.dup)
        expect(r == node1).to be_truthy
      end
    end
  end

  context 'wrapped nodes' do
    before do
      allow(node1).to receive(:neo_id).and_return(1)
      allow(node1).to receive(:foo_prop).and_return(true)
    end
    let(:r) { RelatedNode.new(node1) }

    it 'accepts a wrapped node during initialize' do
      expect(r.instance_variable_get(:@node)).to eq node1
    end

    describe 'when loaded' do
      it 'still has @node set to the wrapped node' do
        r.loaded
        expect(r.instance_variable_get(:@node)).to eq node1
      end
    end

    describe 'related nodes' do
      it 'respond to all methods not defined' do
        expect(node1).to receive(:name)
        r.name
      end

      it 'respond to :class' do
        expect(node1).to receive(:class)
        r.class
      end
    end

    describe 'loaded?' do
      it 'returns true' do
        expect(r.loaded?).to be_truthy
      end
    end

    describe '==' do
      it 'correctly compares nodes' do
        expect(r == node1).to be_truthy
      end
    end

    describe 'respond_to?' do
      it 'works correctly' do
        expect(r.respond_to?(:foo_prop)).to be_truthy
      end
    end
  end

  context 'when invalid' do
    it 'does not accept an invalid initialization param' do
      expect do
        RelatedNode.new(foo: 'bar')
      end.to raise_error(ActiveGraph::InvalidParameterError)
    end
  end
end
