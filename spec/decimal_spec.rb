require 'spec_helper'

module TracLang 

RSpec.describe Decimal do

  describe '.new' do

    context 'given no arguments' do
      it 'creates zero' do
        expect(Decimal.new.prefix).to eq('')
        expect(Decimal.new.value).to eq(0)
        expect(Decimal.new.negative?).to be false
      end
    end

    context 'given one string argument' do
      it 'creates object' do
        expect(Decimal.new('abc')).to be_instance_of(Decimal)
      end
    end

    context 'given non-string argument' do
      it 'raises error' do
        expect { Decimal.new(123) }.to raise_error(ArgumentError)
      end
    end

    context 'given more than one argument' do
      it 'raises error' do
        expect { Decimal.new('abc', 123) }.to raise_error(ArgumentError)
      end
    end
  end

  describe '.prefix' do

    it 'contains string prefix' do
      expect(Decimal.new('abc5').prefix).to eq('abc')
    end

    it 'contains all characters before first sign or numeric' do
      expect(Decimal.new('54+45').prefix).to eq('54')
      expect(Decimal.new('+-+10').prefix).to eq('+-')
    end

  end

  describe '.value' do

    it 'defaults to zero' do
      expect(Decimal.new('').value).to eq(0)
      expect(Decimal.new('abc').value).to eq(0)
      expect(Decimal.new('++-').value).to eq(0)
      expect(Decimal.new('+++').value).to eq(0)
    end

    it 'ignores everything before last sign or last non-numeric' do
      expect(Decimal.new('abc555').value).to eq(555)
      expect(Decimal.new('85-33').value).to eq(-33)
      expect(Decimal.new('101 102').value).to eq(102)
      expect(Decimal.new('+++++1').value).to eq(1)
    end

  end

  describe '.negative' do

    it 'defaults to false' do
      expect(Decimal.new('').negative?).to be false
      expect(Decimal.new('5').negative?).to be false
      expect(Decimal.new('abc').negative?).to be false
    end

    it 'takes the last sign' do
      expect(Decimal.new('+-0').negative?).to be true
      expect(Decimal.new('-+0').negative?).to be false
    end

    it 'works even if there are no numerics' do
      expect(Decimal.new('abab-').negative?).to be true
      expect(Decimal.new('fafa+').negative?).to be false
    end

    it 'matches sign of non-zero value' do
      expect(Decimal.new('-5').negative?).to be true
      expect(Decimal.new('+5').negative?).to be false
    end

  end

  describe '.==' do

    it 'checks all fields' do
      expect(Decimal.new('abc5') == Decimal.new('cde5')).to be false
      expect(Decimal.new('abc5') == Decimal.new('abc6')).to be false
    end

    it 'has multiple ways to express zero' do
      expect(Decimal.new('') == Decimal.new('0')).to be true
      expect(Decimal.new('') == Decimal.new('+0')).to be true
      expect(Decimal.new('-') == Decimal.new('-0')).to be true
      expect(Decimal.new('0') == Decimal.new('-0')).to be false
    end
  end

  describe '.to_s' do
    it 'is same as initializing string' do
      expect(Decimal.new('abc-1').to_s).to eq('abc-1')
      expect(Decimal.new('def-0').to_s).to eq('def-0')
      expect(Decimal.new.to_s).to eq('0')
      expect(Decimal.new('5-').to_s).to eq('5-0')
    end
  end

  describe 'operations' do
    before(:example) do
      @a = Decimal.new('abc1')
      @b = Decimal.new('def-1')
      @c = Decimal.new('5')
      @d = Decimal.new('ruby7')
      @e = Decimal.new('matz14')
    end

    context '+' do
      it 'adds decimals' do
        expect(@a + @c).to be_instance_of(Decimal)
        expect(@a.+(@c).value).to eq(6)
        expect((@a + @c).prefix).to eq('abc')
        expect(@a.+(@b).value).to eq(0)
        expect(@b.+(@b).negative?).to be true
      end
    end

    context '-' do
      it 'subtracts decimals' do
        expect(@c - @a).to be_instance_of(Decimal)
        expect((@c - @a).prefix).to eq('')
        expect((@b - @c).prefix).to eq('def')
        expect(@b.-(@a).value).to eq(-2)
        expect(@b.-(@a).negative?).to be true
        expect((@c - @c).value).to eq(0)
      end
    end

    context '*' do
      it 'multiplies decimals' do
        expect(@b * @c).to be_instance_of(Decimal)
        expect((@b * @c).value).to eq(-5)
        expect((@b * @b).value).to eq(1)
        expect((@b * @b).prefix).to eq('def')
        expect(@c.*(@b.-(@b)).value).to eq(0)
      end

      it 'has precedence over addition and subtraction' do
        expect((@b * @c + @a).prefix).to eq('def')
        expect((@b * @c + @a).value).to eq(-4)
        expect((@a + @d * @c).prefix).to eq('abc')
        expect((@a + @d * @c).value).to eq(36)
        expect((@b * @c - @a).prefix).to eq('def')
        expect((@b * @c - @a).value).to eq(-6)
        expect((@a - @d * @c).prefix).to eq('abc')
        expect((@a - @d * @c).value).to eq(-34)
      end

    end

    context '/' do
      it 'divides decimals' do
        expect((@c / @a).value).to eq(5)
        expect((@c / @b).value).to eq(-5)
        expect((@c / @d).value).to eq(0)
        expect((@d / @c).value).to eq(1)
        expect((@e / @d).value).to eq(2)
      end

      it 'raises error on divide by zero' do
        expect { @d / (@a - @a) }.to raise_error(ZeroDivisionError)
      end
    end

  end
end

end
