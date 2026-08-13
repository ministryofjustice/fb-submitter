require 'rails_helper'
require './lib/string_utils'
RSpec.describe StringUtils do
  describe '.mask' do
    it 'masks the middle of a string' do
      expect(described_class.mask('hello_wild_bear')).to eq('he***ar')
    end

    it 'returns the string unchanged when it has 4 or fewer characters' do
      expect(described_class.mask('test')).to eq('test')
    end

    it 'handles an empty string' do
      expect(described_class.mask('')).to eq('')
    end
  end
end
