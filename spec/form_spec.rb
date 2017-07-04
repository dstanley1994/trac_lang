require 'spec_helper'

module TracLang

RSpec.describe Form do

  describe 'segments' do
    before do
      @f = Form.new('abcdefgh')
    end
    
    context 'nothing found' do
      it 'does nothing' do
        @f.punch('qx', 1)
        expect(@f.value).to eq('abcdefgh')
        expect(@f.segments.all? { |v| v.empty?}).to be true
      end
    end
    
    context 'start of value' do
      it 'punches at start' do
        @f.punch('ab', 1)
        expect(@f.to_s).to eq('<^><1>cdefgh')
      end
    end
    
    context 'end of value' do
      it 'punches at end' do
        @f.punch('gh', 1)
        expect(@f.to_s).to eq('<^>abcdef<1>')
      end
    end
    
    context 'whole value' do
      it 'is nothing but pointers' do
        @f.punch('abcdefgh', 1)
        expect(@f.to_s).to eq('<^><1>')
      end
    end
    
    context 'each value' do
      it 'removes until nothing is left' do
        g = Form.new('abcd')
        g.punch('ab', 1)
        g.punch('cd', 2)
        expect(g.to_s).to eq('<^><1><2>')
        h = Form.new('abcd')
        h.punch('b', 1)
        expect(h.to_s).to eq('<^>a<1>cd')
        h.punch('a', 2)
        expect(h.to_s).to eq('<^><2><1>cd')
        h.punch('d', 3)
        expect(h.to_s).to eq('<^><2><1>c<3>')
        h.punch('c', 4)
        expect(h.to_s).to eq('<^><2><1><4><3>')
      end
    end
    
    context 'spans segment gap' do
      it 'does nothing' do
        @f.punch('b', 1)
        @f.punch('ac', 2)
        expect(@f.to_s).to eq('<^>a<1>cdefgh')
      end
    end
    
    context 'multiple matches' do
      it 'punches each one' do
        g = Form.new('a,b,c,d,e,f')
        g.punch(',', 1)
        expect(g.to_s).to eq('<^>a<1>b<1>c<1>d<1>e<1>f')
      end
      it 'punches except for spans' do
        g = Form.new('ab1a5b2ab3ab')
        g.punch('5', 1)
        g.punch('ab', 2)
        expect(g.to_s).to eq('<^><2>1a<1>b2<2>3<2>')
      end
    end
    
    context 'punch multiple' do
      it 'does all punching' do
        g = Form.new('abcd')
        g.segment_string('b')
        expect(g.to_s).to eq('<^>a<1>cd')
      end
    end
  end
  
  describe 'call character' do
    context 'simple string' do
      it 'moves sequentially' do
        f = Form.new('abcd')
        expect(f.to_s).to eq('<^>abcd')
        expect(f.call_character).to eq('a')
        expect(f.to_s).to eq('a<^>bcd')
        expect(f.call_character).to eq('b')
        expect(f.to_s).to eq('ab<^>cd')
        expect(f.call_character).to eq('c')
        expect(f.to_s).to eq('abc<^>d')
        expect(f.call_character).to eq('d')
        expect(f.to_s).to eq('abcd<^>')
        expect {f.call_character}.to raise_error(Form::EndOfStringError)
      end
    end
    
    context 'segment gaps' do
      it 'jumps the gaps' do
        f = Form.new('a,b,c,d,e,f')
        f.punch(',', 1)
        expect(f.to_s).to eq('<^>a<1>b<1>c<1>d<1>e<1>f')
        expect(f.call_character).to eq('a')
        expect(f.to_s).to eq('a<^><1>b<1>c<1>d<1>e<1>f')
        expect(f.call_character).to eq('b')
        expect(f.to_s).to eq('a<1>b<^><1>c<1>d<1>e<1>f')
      end
    end
  end
  
  describe 'call n characters' do
    
    context 'multiple characters' do
      it 'pulls number of chars asked for' do
        f = Form.new('abcdefg')
        expect(f.call_n('3')).to eq('abc')
        expect(f.call_n('2')).to eq('de')
        expect(f.call_n('-4')).to eq('bcde')
      end
      
      it 'ignores segments gaps' do
        f = Form.new('abcdefghijklmno')
        f.punch('cde', 1)
        f.punch('fgh', 2)
        f.punch('mno', 3)
        expect(f.call_n('3')).to eq('abi')
        expect(f.call_n('3')).to eq('jkl')
        expect {f.call_n('4')}.to raise_error(Form::EndOfStringError)
        expect(f.call_n('-5')).to eq('bijkl')
        expect(f.call_n('2')).to eq('bi')
        expect(f.call_n('3')).to eq('jkl')
      end
      
      it 'moves to end of string over segment gaps' do
        f = Form.new('abcdefg')
        f.punch('g', 1)
        f.punch('f', 2)
        f.punch('b', 3)
        f.punch('a', 4)
        expect(f.call_n('3')).to eq('cde')
        expect(f.call_n('+0')).to eq('')
        expect(f.to_s).to eq('<4><3>cde<2><1><^>')
        expect(f.call_n('-3')).to eq('cde')
        expect(f.call_n('-0')).to eq('')
        expect(f.to_s).to eq('<^><4><3>cde<2><1>')
      end
      
      it 'returns characters to the end without going over' do
        f = Form.new('abcd')
        expect(f.call_n('100')).to eq('abcd')
      end
      
    end
    
  end
  
  describe 'call segment' do
  
    context 'segments' do
      it 'returns all characters between segment gaps' do
        f = Form.new('abcdefg')
        f.punch('c', 1)
        f.punch('e', 2)
        expect(f.to_s).to eq('<^>ab<1>d<2>fg')
        expect(f.call_segment).to eq('ab')
        expect(f.to_s).to eq('ab<1><^>d<2>fg')
        expect(f.call_segment).to eq('d')
        expect(f.to_s).to eq('ab<1>d<2><^>fg')
        expect(f.call_segment).to eq('fg')
        expect(f.to_s).to eq('ab<1>d<2>fg<^>')
      end
      
      it 'returns empty string between two adjancent segment gaps' do
        f = Form.new('abcdefg')
        f.punch('e', 1)
        f.punch('c', 2)
        f.punch('d', 3)
        expect(f.to_s).to eq('<^>ab<2><3><1>fg')
        expect(f.call_segment).to eq('ab')
        expect(f.to_s).to eq('ab<2><^><3><1>fg')
        expect(f.call_segment).to eq('')
        expect(f.to_s).to eq('ab<2><3><^><1>fg')
        expect(f.call_segment).to eq('')
        expect(f.to_s).to eq('ab<2><3><1><^>fg')
        expect(f.call_segment).to eq('fg')
        expect(f.to_s).to eq('ab<2><3><1>fg<^>')
        expect{f.call_segment}.to raise_error(Form::EndOfStringError)
        
        g = Form.new('abcdefg')
        g.punch('b', 1)
        g.punch('a', 2)
        g.punch('f', 3)
        g.punch('g', 4)
        expect(g.to_s).to eq('<^><2><1>cde<3><4>')
        expect(g.call_segment).to eq('')
        expect(g.to_s).to eq('<2><^><1>cde<3><4>')
        expect(g.call_segment).to eq('')
        expect(g.to_s).to eq('<2><1><^>cde<3><4>')
        expect(g.call_segment).to eq('cde')
        expect(g.to_s).to eq('<2><1>cde<3><^><4>')
        expect(g.call_segment).to eq('')
        expect(g.to_s).to eq('<2><1>cde<3><4><^>')
        expect{g.call_segment}.to raise_error(Form::EndOfStringError)
      end
      
      # this comes from Definition and Standard for TRAC T-64 Language pg. 45-46
      it 'returns two empty string for form with only two segment gaps' do
        f = Form.new('ab')
        f.punch('a', 1)
        f.punch('b', 2)
        expect(f.to_s).to eq('<^><1><2>')
        expect(f.call_segment).to eq('')
        expect(f.to_s).to eq('<1><^><2>')
        expect(f.call_segment).to eq('')
        expect{f.call_segment}.to raise_error(Form::EndOfStringError)
      end
      
    end
    
  end
  
  describe 'in string' do
    context 'simple string' do
      it 'returns predessors' do
        f = Form.new('abcdefgh')
        expect(f.in_neutral('ab')).to eq('')
        expect(f.to_s).to eq('ab<^>cdefgh')
        expect(f.in_neutral('de')).to eq('c')
        expect(f.to_s).to eq('abcde<^>fgh')
        expect(f.in_neutral('h')).to eq('fg')
        expect(f.to_s).to eq('abcdefgh<^>')
      end
      
      it 'raises error if not found' do
        f = Form.new('abc')
        expect{f.in_neutral('h')}.to raise_error(Form::EndOfStringError)
      end
      
    end
    
    context 'gaps in middle' do
      it 'can\'t find over segment gaps' do
        f = Form.new('abcdefg')
        f.punch('c', 1)
        f.punch('d', 2)
        expect(f.to_s).to eq('<^>ab<1><2>efg')
        expect{f.in_neutral('bef')}.to raise_error(Form::EndOfStringError)
        # form pointer is not moved on not found
        expect(f.to_s).to eq('<^>ab<1><2>efg')
      end
    end
    
    context 'gaps on end' do
      it 'can\'t move pointer pass segment gaps' do
        f = Form.new('abcdefg')
        f.punch('efg', 1)
        expect(f.in_neutral('d')).to eq('abc')
        expect(f.to_s).to eq('abcd<^><1>')
      end
    end
    
  end
  
  describe 'call' do
    context 'call whole string' do
      it 'returns whole string' do
        f = Form.new('abcdefg')
        expect(f.call_lookup).to eq('abcdefg')
        expect(f.call_lookup('ab')).to eq('abcdefg')
      end
      
      it 'fills segment gaps' do
        f = Form.new('abcdefg')
        f.punch('b', 1)
        f.punch('c', 2)
        f.punch('fg', 3)
        expect(f.to_s).to eq('<^>a<1><2>de<3>')
        expect(f.call_lookup(' hey ', '',' hi ')).to eq('a hey de hi ')
        expect(f.call_lookup('b', ' = ', ' * c')).to eq('ab = de * c')
      end

      it 'ignores args that don\'t correspond to segment gaps' do
        f = Form.new('abcdefg')
        f.punch('c', 1)
        f.punch('g', 2)
        expect(f.to_s).to eq('<^>ab<1>def<2>')
        expect(f.call_lookup('a','b','c')).to eq('abadefb')
      end
      
      it 'doesn\'t fill gaps when arg is empty string' do
        f = Form.new('abcdefg')
        f.punch('c', 1)
        f.punch('b', 2)
        f.punch('def', 3)
        expect(f.to_s).to eq('<^>a<2><1><3>g')
        expect(f.call_lookup).to eq('ag')
        expect(f.call_lookup(' ')).to eq('a g')
      end
    end
    
    context 'form pointer moved' do
      it 'returns string after pointer' do
        f = Form.new('abcdefg')
        f.punch('cd', 1)
        expect(f.to_s).to eq('<^>ab<1>efg')
        expect(f.call_n('3')).to eq('abe')
        expect(f.to_s).to eq('ab<1>e<^>fg')
        expect(f.call_lookup).to eq('fg')
        expect(f.call_lookup('ab')).to eq('fg')
        f.call_return
        expect(f.call_n('2')).to eq('ab')
        expect(f.to_s).to eq('ab<^><1>efg')
        expect(f.call_lookup('isa')).to eq('isaefg')
      end
      
      it 'fills segment gaps after pointer' do
        f = Form.new('abcdefg')
        f.punch('g', 1)
        f.punch('f', 2)
        f.punch('a', 1)
        expect(f.to_s).to eq('<^><1>bcde<2><1>')
        expect(f.call_n('2')).to eq('bc')
        expect(f.to_s).to eq('<1>bc<^>de<2><1>')
        expect(f.call_lookup('plane', ' ')).to eq('de plane')
      end
    end
  end
  
  describe 'to trac string' do
    context 'simple value' do
      it 'preserves value' do
        f = Form.new('abcdefg')
        expect(f.to_trac('test')).to eq("#(DS,test,abcdefg)\n\n")
      end
      it 'remembers position' do
        f = Form.new('abcdefg')
        f.call_character
        f.call_character
        expect(f.to_trac('test')).to eq("#(DS,test,abcdefg)\n#(CN,test,2)\n\n")
      end
    end
    
    context 'segments' do
      it 'shows value with substitutions' do
        f = Form.new('abcdefg')
        f.punch('c', 1)
        f.punch('d', 2)
        expect(f.to_trac('test')).to eq("#(DS,test,ab<1><2>efg)\n#(SS,test,<1>,<2>)\n\n")
      end
      
      it 'calculates correct substitutions' do
        f = Form.new('<1><2><a><3><b><c>')
        f.punch('<a>', 1)
        f.punch('<b>', 2)
        f.punch('<c>', 3)
        expect(f.to_trac('test')).to eq("#(DS,test,<1><2>[1]<3>[2][3])\n#(SS,test,[1],[2],[3])\n\n")
        g = Form.new('<1>[1]{1}a')
        g.punch('a', 1)
        expect(g.to_trac('test')).to eq("#(DS,test,<1>[1]{1}~1~)\n#(SS,test,~1~)\n\n")
      end
      
      it 'remembers position' do
        f = Form.new('abcdefgh')
        f.punch('a', 1)
        f.punch('c', 2)
        f.punch('b', 3)
        f.call_segment
        expect(f.to_trac('test')).to eq("#(DS,test,<1><3><2>defgh)\n#(SS,test,<1>,<2>,<3>)\n#(CS,test)\n\n")
        g = Form.new('abcdefgh')
        g.punch('e', 1)
        g.punch('d', 2)
        g.punch('f', 3)
        g.call_segment
        g.call_segment
        expect(g.to_trac('test')).to eq("#(DS,test,abc<2><1><3>gh)\n#(SS,test,<1>,<2>,<3>)\n#(CN,test,3)\n#(CS,test)#(CS,test)\n\n")
      end
    end
    
  end
  
  describe 'to_s' do
    context 'control characters' do
      it 'converts them to escape sequences' do
        f = Form.new("abc\ndef")
        expect(f.to_s).to eq('<^>abc\\x0adef')
      end
    end
  end
  
end

end
