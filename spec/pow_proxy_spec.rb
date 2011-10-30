require 'pebbles/pow_proxy'

describe Pebbles::PowProxy do

  specify do
    Pebbles::PowProxy.extract_service_name("/api/checkpoint/v1/abc").should eq("checkpoint")
  end

  specify do
    Pebbles::PowProxy.extract_service_name("/api/checkpoint/v1123/abc").should eq("checkpoint")
  end

  specify do
    Pebbles::PowProxy.extract_service_name("/foo/checkpoint/v1/abc").should be_nil
  end

  specify do
    Pebbles::PowProxy.extract_service_name("/api/checkpoint/vavavoom").should be_nil
  end

  specify "query string is ignored if missing" do
    request = stub(:env => {'PATH_INFO' => '/api/checkpoint/v1/foo', 'QUERY_STRING' => ''})
    Pebbles::PowProxy.remap(request).should eq("http://checkpoint.dev/api/checkpoint/v1/foo")
  end

  specify "query string is included where relevant" do
    request = stub(:env => {'PATH_INFO' => '/api/checkpoint/v1/foo', 'QUERY_STRING' => 'data=bar'})
    Pebbles::PowProxy.remap(request).should eq("http://checkpoint.dev/api/checkpoint/v1/foo?data=bar")
  end
end
