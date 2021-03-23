RSpec.shared_examples 'updating deleted columns' do
  it 'does not destroy record' do
    expect{ subject.send(delete_method).not_to change{ subject.class.unscoped.count }}
  end

  it 'updates deleted_at column' do
    expect(subject.deleted_at).to be_blank
    subject.send(delete_method)
    expect(subject.deleted_at).not_to be_blank
  end
end

RSpec.shared_examples 'with soft_delete' do
  describe 'process_soft_delete' do
    let(:delete_method) { :process_soft_delete }
    it_behaves_like 'updating deleted columns'
  end

  describe 'soft_delete!' do
    let(:delete_method) { :soft_delete! }
    it_behaves_like 'updating deleted columns'

    it 'hides record so it\'s not returned by not_deleted scope' do
      expect{subject.send(delete_method)}.to change{ subject.class.not_deleted.count }.by(-1)
    end
  end

  describe 'is_deleted?' do
    it 'returns true for deleted record' do
      subject.soft_delete!
      expect(subject.deleted?).to be_truthy
    end

    it 'returns false for not deleted record' do
      expect(subject.reload.deleted?).to be_falsy
    end
  end
end
