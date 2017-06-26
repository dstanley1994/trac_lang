require 'spec_helper'

module TracLang

RSpec.describe Block do

  describe 'new' do
    it 'adds bindings to hash' do
      b = Bindings.new(['a', 'b'], ['c', 'd'])
      expect(b.fetch('a')).to eq('b')
      expect(b.fetch('c')).to eq('d')
      expect(b.fetch('e')).to eq(nil)
    end
  end
  
  describe 'add' do
    it 'adds single binding to hash' do
      b = Bindings.new
      b.add(['a', 'b'])
      expect(b.fetch('a')).to eq('b')
    end
    
    it 'adds array of bindings to hash' do
      b = Bindings.new
      b.add(['a', 'b'], ['c', 'd'])
      expect(b.fetch('a')).to eq('b')
      expect(b.fetch('c')).to eq('d')
    end
    
    it 'overrides existing binding' do
      b = Bindings.new(['a', 'b'], ['c', 'd'])
      b.add('a', 'q')
      expect(b.fetch('a')).to eq('q')
    end
  end
  
  describe 'fetch binding' do
    it 'fetches binding' do
      b = Bindings.new(['a', 'b'], ['c', 'd'])
      expect(b.fetch_binding('a')).to eq(['a', 'b'])
    end
  end
  
  describe 'delete' do
    it 'removes binding' do
      b = Bindings.new(['a', 'b'], ['c', 'd'])
      b.delete('a')
      expect(b.fetch('a')).to eq(nil)
    end
    
    it 'does nothing if binding doesn\'t exist' do
      b = Bindings.new(['a', 'b'], ['c', 'd'])
      b.delete('q')
      expect(b.fetch('a')).to eq('b')
      expect(b.fetch('c')).to eq('d')
      expect(b.fetch('e')).to eq(nil)
    end
  end
  
  describe 'clear' do
    it 'deletes all bindings' do 
      b = Bindings.new(['a', 'b'], ['c', 'd'])
      b.clear
      expect(b.fetch('a')).to eq(nil)
      expect(b.fetch('c')).to eq(nil)
    end
  end
end

end
