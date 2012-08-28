require 'pebblebed/labels'

describe Pebblebed::Labels do

  describe "default labels" do
    subject { Pebblebed::Labels.new('a.b.c') }
    its(:expanded) {  should eq('label_0' => "a", 'label_1' => "b", 'label_2' => "c") }
  end

  describe "customized labels" do
    subject { Pebblebed::Labels.new('p.r.q', :prefix => 'dot', :suffix => '') }
    its(:expanded) { should eq('dot_0_' => 'p', 'dot_1_' => 'r', 'dot_2_' => 'q') }
  end

end
