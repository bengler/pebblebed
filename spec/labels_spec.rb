require 'pebblebed/labels'

describe Pebblebed::Labels do

  describe "default labels" do
    subject { Pebblebed::Labels.new('a.b.c') }
    its(:expanded) {  should eq('label_0' => "a", 'label_1' => "b", 'label_2' => "c") }
  end

  describe "with a stop label" do
    subject { Pebblebed::Labels.new('a.b.c', :stop => nil) }
    its(:expanded) {  should eq('label_0' => "a", 'label_1' => "b", 'label_2' => "c", 'label_3' => nil) }
  end

  describe "customized labels" do
    subject { Pebblebed::Labels.new('p.r.q', :prefix => 'dot', :suffix => '', :stop => '<END>') }
    its(:expanded) { should eq('dot_0_' => 'p', 'dot_1_' => 'r', 'dot_2_' => 'q', 'dot_3_' => '<END>') }
  end

  describe "next label" do
    subject { Pebblebed::Labels.new('a.b.c', :prefix => 'thing') }
    its(:next) { should eq('thing_3') }
  end


end
