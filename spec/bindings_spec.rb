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
    
    it 'can be used to create new binding' do
      b = Bindings.new(['a', 'b'], ['c', 'd'])
      names = b.map { |n, v| n }
      names << 'e'
      expect(names).to eq(['a', 'c', 'e'])
      new_ary = names.map { |n| b.fetch_binding(n) }.compact
      expect(new_ary).to eq([['a', 'b'], ['c', 'd']])
      c = Bindings.new(*new_ary)
      expect(c.bindings).to eq({'a' => 'b', 'c' => 'd'})
      expect(c.fetch('a')).to eq('b')
      expect(c.fetch('c')).to eq('d')
      expect(c.fetch('e')).to eq(nil)
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
  
  describe 'each' do
    it 'enumerates all bindings' do
      b = Bindings.new(['a', 'b'], ['c', 'd'])
      expect(b.each).to be_instance_of(Enumerator)
      ary = []
      b.each { |n, v| ary << n }
      expect(ary).to eq(['a', 'c'])
      ary = []
      b.each { |n, v| ary << v }
      expect(ary).to eq(['b', 'd'])
    end
  end
  
end

end
