require 'spec_helper'

module TracLang

RSpec.describe Executor do

  describe 'execute' do
    before do
      @b = Bindings.new
      @e = Executor.new(Dispatch.new(@b, {}))
    end
    
    context 'valid string' do
      it 'executes the string' do
        @b.add(['a', Form.new('bcd')])
        @e.execute('#(DS,a,efg)')
        expect(@b.fetch('a').value).to eq('efg')
      end
    end
    
    context 'mismatched parents' do
      it 'throws reset' do
        expect {@e.execute('(a')}.to throw_symbol(:reset)
        expect {@e.execute(')')}.to throw_symbol(:reset)
        expect {@e.execute('(')}.to throw_symbol(:reset)
        expect {@e.execute('#(a')}.to throw_symbol(:reset)
      end
    end
    
    context 'simple text' do
      it 'ignored' do
        @b.clear
        @e.execute('comments are ignored')
        @e.execute('#a')
        @e.execute('###')
        expect(@b.bindings.empty?).to be true
      end
    end
  end
  
  describe 'load' do
    before do
      @b = Bindings.new
      @e = Executor.new(Dispatch.new(@b, {}))
    end
    
    context 'meta char received' do
      it 'executes' do 
        expect(@e.load('test', 5, 'comments are ignored')).to be true
        expect(@e.load('test', 5, '#(DS,a,abc)\'')).to be true
        expect(@b.fetch('a').value).to eq('abc')
      end
    end
    
    context 'mismatched parens' do
      it 'returns false after meta char' do
        expect(@e.load('test', 5, '((')).to be true
        expect(@e.load('test', 5, "'")).to be false
      end
    end

    context 'successive commands' do
      it 'executes all of them' do
        expect(@e.load('test', 5, <<-END_TRAC)).to be true
        This is a comment
        #(PS,Hello World!)
        #(DS,a,abcd)
        #(SS,a,b)
        #(DS,b,#(a,e))'
        END_TRAC
        expect(@b.fetch('a').value).to eq('acd')
        expect(@b.fetch('b').value).to eq('aecd')
      end
      
      it 'doesn\'t check number of parameters' do
        @b.clear
        expect(@e.load('test', 5, <<-END_TRAC)).to be true
        #(DS,a,ab,cd,ef,gh)
        #(SS,a,b)
        #(DS,b,#(a,e),f,g)'
        END_TRAC
        expect(@b.fetch('a').value).to eq('a')
        expect(@b.fetch('b').value).to eq('ae')
      end
    end
    
  end
  
end

end
