require 'spec_helper'

describe Pebbles::Http do 
  it "knows how to pack params into a http query string" do
    Pebbles::Http.send(:url_with_params, URI("/dingo/"), {a:1}).should eq "/dingo/?a=1"
  end

  it "knows how to combine url and parmas with results of pathbuilder" do
    url, params = Pebbles::Http.send(:url_and_params_from_args, URI("http://example.org/api"), {a:1}) do
      foo.bar(:b => 2)
    end
    params.should eq(:a => 1, :b => 2)
    url.to_s.should eq "http://example.org/api/foo/bar"
  end

  it "raises an exception if there is a http-error" do
    -> { Pebbles::Http.send(:handle_http_errors, DeepStruct.wrap(status:400, url:"/foobar", body:"Oh noes")) }.should raise_error Pebbles::HttpError
  end

end
