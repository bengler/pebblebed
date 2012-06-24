require 'spec_helper'
require 'pebblebed/river/subscription'

describe Pebblebed::River::Subscription do

  Subscription = Pebblebed::River::Subscription

  specify 'simple, direct match' do
    options = {:event => 'create', :klass => 'post.event', :path => 'feed.bagera'}
    subscription = Subscription.new(options)
    subscription.queries.should eq(['create._.post.event._.feed.bagera'])
  end

  specify 'simple wildcard match' do
    options = {:event => '*.create', :klass => 'post.*', :path => '*.bagera.*'}
    Subscription.new(options).queries.should eq(['*.create._.post.*._.*.bagera.*'])
  end

  describe "anything matchers" do

    specify 'match anything (duh)' do
      options = {:event => '**', :klass => '**', :path => '**'}
      Subscription.new(options).queries.should eq(['#._.#._.#'])
    end

    specify 'match anything if not specified' do
      Subscription.new.queries.should eq(['#._.#._.#'])
    end

  end

  it 'handles "or" queries' do
    options = {:event => 'create|delete', :klass => 'post', :path => 'bagera|bandwagon'}
    expected = ['create._.post._.bagera', 'delete._.post._.bagera', 'create._.post._.bandwagon', 'delete._.post._.bandwagon'].sort
    Subscription.new(options).queries.sort.should eq(expected)
  end

  describe "optional paths" do
    it { Subscription.new.pathify('a.b').should eq(['a.b']) }
    it { Subscription.new.pathify('a.^b.c').should eq(%w(a a.b a.b.c)) }
  end

  it "handles optional queries" do
    options = {:event => 'create', :klass => 'post', :path => 'feeds.bagera.^fb.concerts'}
    expected = ['create._.post._.feeds.bagera', 'create._.post._.feeds.bagera.fb', 'create._.post._.feeds.bagera.fb.concerts'].sort
    Subscription.new(options).queries.sort.should eq(expected)
  end

  it "combines all kinds of weird stuff" do
    options = {:event => 'create', :klass => 'post', :path => 'a.^b.c|x.^y.z'}
    expected = [
      'create._.post._.a',
      'create._.post._.a.b',
      'create._.post._.a.b.c',
      'create._.post._.x',
      'create._.post._.x.y',
      'create._.post._.x.y.z',
    ].sort
    Subscription.new(options).queries.sort.should eq(expected)
  end

end
