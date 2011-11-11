module Pebbles 
  class CheckpointClient < Pebbles::GenericClient
    def me
      return @identity if @identity_checked
      @identity_checked = true
      @identity = get("/identities/me")[:identity]
    end

    def god?
      !!me.god if me
    end
  end
end