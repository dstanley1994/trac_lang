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

end

end
