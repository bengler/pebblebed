require 'pebblebed/uid'
require 'pebblebed/labels'

describe Pebblebed::Labels do

  describe "default labels" do
    subject { Pebblebed::Labels.new('a.b.c') }

    describe '#expanded' do
      subject { super().expanded }
      it {  is_expected.to eq('label_0' => "a", 'label_1' => "b", 'label_2' => "c") }
    end

    describe '#wildcard?' do
      subject { super().wildcard? }
      it { is_expected.to eq(false) }
    end
  end

  describe "with a stop label" do
    subject { Pebblebed::Labels.new('a.b.c', :stop => nil) }

    describe '#expanded' do
      subject { super().expanded }
      it {  is_expected.to eq('label_0' => "a", 'label_1' => "b", 'label_2' => "c", 'label_3' => nil) }
    end
  end

  describe "customized labels" do
    subject { Pebblebed::Labels.new('p.r.q', :prefix => 'dot', :suffix => '', :stop => '<END>') }

    describe '#expanded' do
      subject { super().expanded }
      it { is_expected.to eq('dot_0_' => 'p', 'dot_1_' => 'r', 'dot_2_' => 'q', 'dot_3_' => '<END>') }
    end
  end

  describe "next label" do
    subject { Pebblebed::Labels.new('a.b.c', :prefix => 'thing') }

    describe '#next' do
      subject { super().next }
      it { is_expected.to eq('thing_3') }
    end
  end

  describe "with wildcard *" do
    subject { Pebblebed::Labels.new('a.b.c.*') }

    describe '#expanded' do
      subject { super().expanded }
      it { is_expected.to eq('label_0' => "a", 'label_1' => "b", 'label_2' => "c") }
    end

    describe '#wildcard?' do
      subject { super().wildcard? }
      it { is_expected.to eq(true) }
    end
  end

end
