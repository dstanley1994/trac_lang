require 'spec_helper'

module TracLang

RSpec.describe Dispatch do

  describe 'table' do
    context 'class' do
      it 'has all mnemonic commands' do
        # basic form commands
        expect(Dispatch.table.has_key?(:ds)).to be true
        expect(Dispatch.table.has_key?(:ss)).to be true
        expect(Dispatch.table.has_key?(:cl)).to be true
        # form partial calls
        expect(Dispatch.table.has_key?(:cc)).to be true
        expect(Dispatch.table.has_key?(:cs)).to be true
        expect(Dispatch.table.has_key?(:cn)).to be true
        expect(Dispatch.table.has_key?(:in)).to be true
        expect(Dispatch.table.has_key?(:cr)).to be true
        # io
        expect(Dispatch.table.has_key?(:rs)).to be true
        expect(Dispatch.table.has_key?(:rc)).to be true
        expect(Dispatch.table.has_key?(:cm)).to be true
        expect(Dispatch.table.has_key?(:ps)).to be true
        # tests
        expect(Dispatch.table.has_key?(:eq)).to be true
        expect(Dispatch.table.has_key?(:gr)).to be true
        # decimal math
        expect(Dispatch.table.has_key?(:ad)).to be true
        expect(Dispatch.table.has_key?(:sb)).to be true
        expect(Dispatch.table.has_key?(:ml)).to be true
        expect(Dispatch.table.has_key?(:dv)).to be true
        # octal math
        expect(Dispatch.table.has_key?(:bu)).to be true
        expect(Dispatch.table.has_key?(:bi)).to be true
        expect(Dispatch.table.has_key?(:bc)).to be true
        expect(Dispatch.table.has_key?(:bs)).to be true
        expect(Dispatch.table.has_key?(:br)).to be true
        # blocks
        expect(Dispatch.table.has_key?(:fb)).to be true
        expect(Dispatch.table.has_key?(:sb)).to be true
        expect(Dispatch.table.has_key?(:eb)).to be true
        # form storage
        expect(Dispatch.table.has_key?(:ln)).to be true
        expect(Dispatch.table.has_key?(:dd)).to be true
        expect(Dispatch.table.has_key?(:da)).to be true
        # debug commands
        expect(Dispatch.table.has_key?(:pf)).to be true
        expect(Dispatch.table.has_key?(:tn)).to be true
        expect(Dispatch.table.has_key?(:tf)).to be true
        expect(Dispatch.table.has_key?(:hl)).to be true
      end
    end
  end
end

end
