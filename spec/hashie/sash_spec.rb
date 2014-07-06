require 'spec_helper'

describe Hashie::Sash do
  before(:all) do
    FileUtils.mkdir_p 'tmp'
  end

  before(:each) do
    @filename = 'tmp/sash_savefile.yaml'
    @s = Hashie::Sash.new(options: { file: @filename })
    @s[:before_each] = true
  end

  after(:all) do
    FileUtils.rm @filename if @filename
  end

  it 'Can pass overrides via overrides:{}' do
    @s2 = Hashie::Sash.new(overrides: { foo: :bar })
    expect(@s2).to include(:foo)
  end

  it 'will fail gracefully if nothing to load.' do
    @s.save
    FileUtils.rm @filename
    expect(@s.load).to be {}
    @s.file = nil
    expect(@s.load).to be {}
    FileUtils.touch @filename
    expect(@s.load).to be {}
  end

  it 'will raise an exception if you pass in unknown arguments to new.' do
    @s2 = expect { Sash.new(foo: 'bar') }.to raise_error
  end

  describe 'Saving' do
    it 'can save' do
      @s['foo'] = :bar
      @s.save
      @s2 = Hashie::Sash.new(options: { file: @filename })
      @s2.load
      expect(@s2['foo']).to eq :bar
    end

    it 'can set the mode' do
      @s.mode = 0600
      @s.set_mode
      @s.save
      # I have no idea why you put in 0600, 0600 becomes 384, and out comes 33152.
      # when I figure out where the conversion is going wrong, I'll update this.
      expect(File.stat(@s.file).mode).to eq 33_152
    end

    it 'can auto save' do
      @s = Hashie::Sash.new(options: { file: @filename, auto_save: true })
      @s[:auto_save] = true
      @s2 = Hashie::Sash.new(options: { file: @filename })
      @s2.load
      expect(@s2[:auto_save]).to be true
    end

    it 'can auto load' do
      @s[:auto_load] = true
      @s.save
      @s2 = Hashie::Sash.new(options: { file: @filename, auto_load: true })
      expect(@s2[:auto_load]).to be true
    end

    # We save twice because in order to produce a backup file, we need an original.
    it 'can make a backup file' do
      @s.backup = true
      @s[:backup] = 'something'
      @s.save
      @s.save
      expect(File.exist?(@s.backup_file)).to eq(true)
    end

    it 'will clear before load, destroying previous contents' do
      @s[:clear] = 'clear'
      @s.load
      expect(@s[:clear]).to be_nil
    end
  end

  it 'will behave like a normal Hash' do
    expect(@s.kind_of?(Hash)).to eq(true)
  end

end
