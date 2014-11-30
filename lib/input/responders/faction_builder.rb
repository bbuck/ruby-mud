module Input
  module Responder
    class FactionBuilder < Base
    end
  end
end

Input::Manager.register_responder(:faction_builder, Input::Responder::FactionBuilder)