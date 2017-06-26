require 'spec_helper'

module TracLang

RSpec.describe Expression do

  describe 'creation' do
    it 'sets first argument as command' do
      e = Expression.new
      e.concat('a')
      e.concat('b')
      expect(e.size).to eq(1)
      expect(e.command).to eq(:ab)
    end
    
    it 'sets rest of arguments as trac arguments' do
      e = Expression.new
      e.concat('a')
      e.newarg
      e.concat('b')
      e.newarg
      e.concat('c')
      expect(e.to_s).to eq('#/a*b*c/')
      expect(e.size).to eq(3)
      expect(e.trac_args).to eq(['b', 'c'])
      expect(e.args).to eq(['a', 'b', 'c'])
    end
    
    it 'can be set to active or neutral' do
      e = Expression.new
      expect(e.active?).to be true
      e.active = false
      expect(e.active?).to be false
    end
    
    it 'downcases commands' do
      e = Expression.new
      e.concat('DS')
      expect(e.command).to eq(:ds)
    end
    
  end
  
end

end
