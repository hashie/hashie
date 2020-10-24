RSpec.shared_examples 'Dash default handling' do |property, name = property|
  it 'uses the default when initializing' do
    expect(test.new(name => nil).public_send(property)).to eq ''
  end

  it 'allows you to set the value to nil with the hash writer' do
    trash = test.new(name => 'foo')
    trash[name] = nil

    expect(trash.public_send(property)).to be_nil
  end

  it 'allows you to set the value to nil with the method writer' do
    trash = test.new(name => 'foo')
    trash[name] = nil

    expect(trash.public_send(property)).to be_nil
  end

  it 'uses the default when updating with defaults' do
    trash = test.new(name => 'foo')
    trash.update_attributes!(name => nil)

    expect(trash.public_send(property)).to eq ''
  end
end
