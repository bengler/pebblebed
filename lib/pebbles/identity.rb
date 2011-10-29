require 'deepstruct'

module Pebbles
  class Identity < DeepStruct::HashWrapper
    class << self
      def find(id)
        attributes = Http.get_json("http://#{Pebbles.host}/api/checkpoint/v1/identities/#{id}")['identity']        
        Identity.new(attributes) if attributes
      end
    end    
  end
end