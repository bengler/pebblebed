require 'pebblebed/pow_proxy'

describe Pebblebed::PowProxy do
  specify "/v123 is a valid api path" do
    Pebblebed::PowProxy.api_path?('/v123').should be_true
  end

  specify "/v123/dingodango is a valid api path" do
    Pebblebed::PowProxy.api_path?('/v123/dingodango').should be_true
  end

  specify "/actionjackson is not a valid api path" do
    Pebblebed::PowProxy.api_path?('/actionjackson').should be_false
  end

  specify "/vavavooom is not a valid api path" do
    Pebblebed::PowProxy.api_path?('/vavavoom').should be_false
  end

  specify do
    Pebblebed::PowProxy.remap_path("/api/checkpoint/v1/abc").should eq(["checkpoint", "/v1/abc"])
  end

  specify do
    Pebblebed::PowProxy.remap_path("/foo/checkpoint/v1/abc").should be_nil
  end

  specify do
    Pebblebed::PowProxy.remap_path("/api/checkpoint/vavavoom").should be_nil
  end

  specify "query string is ignored if missing" do
    request = stub(:env => {'PATH_INFO' => '/api/checkpoint/v1/foo', 'QUERY_STRING' => ''})
    Pebblebed::PowProxy.remap(request).should eq("http://checkpoint.dev/api/v1/foo")
  end

  specify "query string is included where relevant" do
    request = stub(:env => {'PATH_INFO' => '/api/checkpoint/v1/foo', 'QUERY_STRING' => 'data=bar'})
    Pebblebed::PowProxy.remap(request).should eq("http://checkpoint.dev/api/v1/foo?data=bar")
  end
end
