require 'spec_helper'

module TracLang

RSpec.describe Octal do

  describe '.new' do
    context 'given no arguments' do
      it 'creates zero' do
        expect(Octal.new.value).to eq(0)
      end
    end

    context 'given one string argument' do
      it 'creates octal' do
        expect(Octal.new('abc')).to be_instance_of(Octal)
      end
    end

    context 'given empty string' do 
      it 'creates empty value' do
        expect(Octal.new('').value).to eq(0)
        expect(Octal.new('').size).to eq(0)
      end
    end

    context 'given non-string argument' do
      it 'rasise arugment error' do
        expect { Octal.new(123) }.to raise_error(ArgumentError)
      end
    end

    context 'given multiple arguments' do
      it 'raises argument error' do
        expect { Octal.new(1, 2) }.to raise_error(ArgumentError)
      end
    end

  end

  describe '.value' do
    context 'given mixed string' do
      before(:example) do
        @i = Octal.new('abc123')
      end

      it 'converts numeric portion' do
        expect(@i.value).to eq(0123)
        expect(@i.size).to eq(3)
      end
    end

    context 'given mixed numeric' do
      it 'only converts trailing octal digits' do
        expect(Octal.new('1995').value).to eq(5)
        expect(Octal.new('2019').value).to eq(0)
        expect(Octal.new('07').value).to eq(7)
      end
    end

  end

  describe '.size' do
    context 'given mixed numeric' do
      it 'only counts trailing octal digits' do
        expect(Octal.new('1995').size).to eq(1)
        expect(Octal.new('2019').size).to eq(0)
        expect(Octal.new('07').size).to eq(2)
      end
    end
  end

  describe '.==' do
    it 'compares size and value' do
      expect(Octal.new('007') == Octal.new('7')).to be false
    end
    it 'ignores string prefix' do
      expect(Octal.new('a7') == Octal.new('b7')).to be true
    end
  end

  describe 'to_s' do
    it 'converts octal to string' do
      expect(Octal.new('007').to_s).to eq('007')
    end
    
    it 'handles negatives correctly' do
      expect(Octal.new('717').to_s).to eq('717')
    end
    
  end
  
  describe 'bitwise and' do
    it 'calculates correctly' do
      expect((Octal.new('16') & Octal.new('1')).to_s).to eq('0')
    end
  end
  
  describe 'bitwise or' do
    it 'calculates correctly' do
      expect((Octal.new('70') | Octal.new('7')).to_s).to eq('77')
    end
  end
  
  describe 'bit complement' do
    it 'creates new Octal' do
      expect(~Octal.new('07')).to be_instance_of(Octal)
    end
    
    it 'calculates correctly' do
      expect((~Octal.new('07')).to_s).to eq('70')
      expect((~Octal.new('761')).to_s).to eq('016')
    end
  end
  
  describe 'bit shift' do
    it 'calculates correctly' do
      expect(Octal.new('7').shift(Decimal.new('-1')).to_s).to eq('3')
    end
  end
  
  describe 'bit rotate' do
    before do
      @dpos = Decimal.new('1')
      @dneg = Decimal.new('-1')
    end
    it 'calculates correctly' do
      expect(Octal.new('7').rotate(@dpos).to_s).to eq('7')
      expect(Octal.new('7').rotate(@dneg).to_s).to eq('7')
      expect(Octal.new('5').rotate(@dpos).to_s).to eq('3')
      expect(Octal.new('3').rotate(@dneg).to_s).to eq('5')
    end
  end
end

end
