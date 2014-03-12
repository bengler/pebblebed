# encoding: utf-8

require 'spec_helper'
require 'yajl/json_gem'
require 'pebblebed/http'
require 'pebblebed/tracing'
require 'deepstruct'

describe Pebblebed::Tracing do

  subject do
    Pebblebed::Tracing
  end

  describe '#current_id' do
    it 'returns nil if no current ID' do
      subject.current_id.should eq nil
    end
  end

  describe '#current_id!' do
    it 'returns new ID' do
      subject.current_id!.should =~ Pebblebed::Tracing::VALID_ID_PATTERN
    end

    it 'returns current ID' do
      subject.with do
        subject.current_id!.should eq subject.current_id
      end
    end
  end

  describe '#current_id=' do
    it 'sets ID' do
      subject.current_id = 'blah'
      subject.current_id.should eq 'blah'
    end
  end

  describe '#with' do
    it 'ensures an ID for the block' do
      id = subject.current_id
      id.should_not eq nil
      subject.with do
        subject.current_id.should_not be_nil
        subject.current_id.should_not eq id
      end
      subject.current_id.should eq id
      subject.current_id = nil
    end

    it 'set custom ID if given an argument' do
      subject.current_id = nil
      subject.with('the-revolution-might-be-televised') do
        subject.current_id.should eq 'the-revolution-might-be-televised'
      end
      subject.current_id.should be_nil
    end
  end

  describe 'HTTP client' do
    it "sends current ID to service" do
      subject.with("the-revolution-will-be-televised") do
        response = Pebblebed::Http.get(mock_pebble_url, {hello: 'world'})

        result = JSON.parse(response.body)
        result['HTTP_PEBBLEBED_TRACE'].should eq 'the-revolution-will-be-televised'
      end
    end

    it "sends no ID to service if there is no ID" do
      subject.current_id = nil

      response = Pebblebed::Http.get(mock_pebble_url, {hello: 'world'})

      result = JSON.parse(response.body)
      result.should_not include('HTTP_PEBBLEBED_TRACE')
    end
  end

  describe 'Rack handler' do

    let :app do
      Class.new {
        def call(env)
          [200, {}, "viva la revolución: #{Pebblebed::Tracing.current_id}"]
        end
      }.new
    end

    let :handler do
      Pebblebed::Tracing.new(app)
    end

    it 'picks up ID from header' do
      subject.current_id = nil
      _, headers, body = handler.call({
        'HTTP_PEBBLEBED_TRACE' => '1234'
      })
      body.should eq "viva la revolución: 1234"
      headers.should include('Pebblebed-Trace' => '1234')
    end

    it 'generates new ID if not passed in header' do
      subject.current_id = nil
      _, headers, body = handler.call({})
      body.should =~ /viva la revolución: .*/
      if body =~ /viva la revolución: (.*)/
        id = $1
        id.should =~ Pebblebed::Tracing::VALID_ID_PATTERN
        headers.should include('Pebblebed-Trace' => id)
      end
    end

  end

end
