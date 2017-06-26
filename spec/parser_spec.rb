require 'spec_helper'

module TracLang 

  RSpec.describe Parser do

    describe 'errors' do

      before do
        @p = Parser.new
        @failer = proc { fail 'unreachable' }
        @empty_result = {value: '', force: false}
      end
    
      context 'given bad string' do
        it 'sends reset' do
          expect {@p.parse('(a', &@failer)}.to throw_symbol(:reset)
          expect {@p.parse(')', &@failer)}.to throw_symbol(:reset)
          expect {@p.parse('(', &@failer)}.to throw_symbol(:reset)
          expect {@p.parse('#(a', &@failer)}.to throw_symbol(:reset)
        end
      end

      context 'given string without enclosing expression' do
        it 'ignores' do
          @p.parse('a', &@failer)
          @p.parse('(a)', &@failer)
          @p.parse('#a', &@failer)
          @p.parse('###', &@failer)
        end
      end
      
      context 'given neutral expression without enclosing expression' do
        it 'ingores' do
          @p.parse('##(a)') { @empty_result }
        end
      end
      
      context 'given valid string' do
        it 'creates expression' do
          @p.parse('#(a)') do |e|
            expect(e.active).to be true
            expect(e.command).to eq(:a)
            expect(e.size).to eq(1)
            @empty_result
          end
          
          @p.parse('##(n)') do |e|
            expect(e.active).to be false
            expect(e.command).to eq(:n)
            expect(e.size).to eq(1)
            @empty_result
          end
          
          @p.parse('#(a,b,c,d)') do |e|
            expect(e.active).to be true
            expect(e.command).to eq(:a)
            expect(e.size).to eq(4)
            expect(e.trac_args).to eq(['b','c','d'])
            @empty_result
          end
          
          @p.parse('#(a,,,,)') do |e|
            expect(e.size).to eq(5)
            expect(e.trac_args).to eq(['','','',''])
            @empty_result
          end
        end
      end
      
      context 'given hashes without parens' do
        it 'copies them to arg' do
          @p.parse('#(a,#)') do |e|
            expect(e.trac_args[0]).to eq('#')
            @empty_result
          end
          @p.parse('#(a,##)') do |e|
            expect(e.trac_args[0]).to eq('##')
            @empty_result
          end
          @p.parse('#(a,###)') do |e|
            expect(e.trac_args[0]).to eq('###')
            @empty_result
          end
        end
      end
      
      context 'given balanced parens' do
        it 'protects text' do
          @p.parse('#(a,(#(b)))') do |e|
            expect(e.command).to eq(:a)
            expect(e.trac_args[0]).to eq('#(b)')
            @empty_result
          end
          @p.parse('#(a,(b,(c,d),(),e))') do |e|
            expect(e.trac_args[0]).to eq('b,(c,d),(),e')
            @empty_result
          end
        end
      end
      
      context 'nested expression' do
        it 'executes in turn' do
          first = true
          @p.parse('#(a,#(b))') do |e|
            if first
              expect(e.command).to eq(:b)
              expect(e.size).to eq(1)
              first = false
              {value: 'b', force: false}
            else
              expect(e.command).to eq(:a)
              expect(e.size).to eq(2)
              expect(e.trac_args[0]).to eq('b')
              @empty_result
            end
          end
          first = true
          @p.parse('#(a,#(b,(#(c))))') do |e|
            if first
              expect(e.command).to eq(:b)
              expect(e.size).to eq(2)
              expect(e.trac_args[0]).to eq('#(c)')
              first = false
              @empty_result
            else
              expect(e.command).to eq(:a)
              expect(e.size).to eq(2)
              @empty_result
            end
          end
        end
      end
      
      context 'active expression' do 
        it 'is scanned again' do
          nesting = 0
          @p.parse('#(a,#(b,(#(c,))))') do |e|
            case nesting
            when 0
              expect(e.command).to eq(:b)
              expect(e.size).to eq(2)
              expect(e.trac_args[0]).to eq('#(c,)')
              nesting = 1
              {value: e.trac_args[0], force: false}
            when 1
              expect(e.command).to eq(:c)
              expect(e.trac_args[0]).to eq('')
              nesting = 2
              {value: e.trac_args[0], force: false}
            when 2
              expect(e.command).to eq(:a)
              expect(e.size).to eq(2)
              expect(e.trac_args[0]).to eq('')
              {value: e.trac_args[0], force: false}
            else
              fail 'wrong index'
              @empty_result
            end
          end
        end
      end
      
      context 'neutral expression' do
        it 'is copied verbatim' do
          nesting = 0
          @p.parse('#(a,##(b,(#(c,))))') do |e|
            case nesting
            when 0
              expect(e.command).to eq(:b)
              expect(e.size).to eq(2)
              expect(e.trac_args[0]).to eq('#(c,)')
              nesting = 1
              {value: e.trac_args[0], force: false}
            when 1
              expect(e.command).to eq(:a)
              expect(e.trac_args[0]).to eq('#(c,)')
              nesting = 2
              {value: e.trac_args[0], force: false}
            when 2
              expect(e.command).to eq(:c)
              expect(e.size).to eq(2)
              expect(e.trac_args[0]).to eq('')
              {value: e.trac_args[0], force: false}
            else
              fail 'wrong index'
              @empty_result
            end
          end
        end
      end
      
      context 'force is true' do
        it 'overrides neutral' do
          nesting = 0
          @p.parse('#(a,##(b,(#(c,))))') do |e|
            case nesting
            when 0
              expect(e.command).to eq(:b)
              expect(e.size).to eq(2)
              expect(e.trac_args[0]).to eq('#(c,)')
              nesting = 1
              {value: e.trac_args[0], force: true}
            when 1
              expect(e.command).to eq(:c)
              expect(e.trac_args[0]).to eq('')
              nesting = 2
              {value: e.trac_args[0], force: false}
            when 2
              expect(e.command).to eq(:a)
              expect(e.size).to eq(2)
              expect(e.trac_args[0]).to eq('')
              {value: e.trac_args[0], force: false}
            else
              fail 'wrong index'
              @empty_result
            end
          end
        end
      end
      
    end
  end

end
