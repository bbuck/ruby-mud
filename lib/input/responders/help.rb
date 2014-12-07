module Input
  module Responder
    class Help < Base
      # --- Template Helpers -------------------------------------------------
      # --- Public Helpers ---------------------------------------------------
      # --- Responders -------------------------------------------------------

      parse_input_with(/\Ahelp colors?\z/) do
        render("general.help.color", :write)
      end

      # --- Private Helpers --------------------------------------------------
    end
  end
end

Input::Manager.register_responder(:standard, Input::Responder::Help)
