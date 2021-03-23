RSpec.shared_examples 'with next_id' do
  it 'returns next_id if previous record exists' do
    expect(subject.class.next_id).to eq subject.class.maximum(subject.class.primary_key) + 1
  end

  describe 'defaults' do
    it 'sets primary key on new object' do
      new_record          = subject.class.new
      primary_key_method  = subject.class.primary_key
      expect(new_record.send(primary_key_method)).not_to be_blank
      expect(new_record.send(primary_key_method)).to eq subject.class.next_id
    end

    it 'sets default quantity before validation' do
      new_record          = subject.class.new
      primary_key_method  = subject.class.primary_key
      next_id = subject.class.next_id

      new_record.send("#{subject.class.primary_key}=", nil)
      expect(new_record.send(primary_key_method)).to be_blank
      new_record.valid?
      expect(new_record.send(primary_key_method)).not_to be_blank
      expect(new_record.send(primary_key_method)).to eq next_id
    end
  end
end
