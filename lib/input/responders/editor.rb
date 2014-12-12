module Input
  module Responder
    class Editor < Base
      allow_blank_input

      IDENTIFIER_RX = "[a-z_][A-Za-z_0-9]*[a-zA-Z0-9_?!]"
      CLASS_IDENTIFIER_RX = "@@[a-zA-Z_][a-Za-z_0-9]*"
      INSTANCE_IDENTIFIER_RX = "@[a-zA-Z_][a-Za-z_0-9]*"
      COMMENT = /\A\s*\#[\s\S]*\z/
      HIGHLIGHT = {
        symbol: {
          rx: /(?<![fb])(:[\w][\w\d]*?)(?=\b)/i,
          replacement: "[f:cyan]$1[reset]"
        },
        constant: {
          rx: /(?<=\b)([A-Z][a-zA-Z_]*)(?=(?:[^"\\]*(?:\\.|"([^"\\]*\\.)*[^"\\]*"))*[^"]*\z)/,
          replacement: "[f:yellow:b]$1[reset]"
        },
        instance_method: {
          rx: /(#{IDENTIFIER_RX})\s+?do\b/,
          replacement: "[f:magenta]$1 [f:blue:b]do[reset]"
        },
        instance_class_identifier: {
          rx: /(@@?#{IDENTIFIER_RX})/,
          replacement: "[f:cyan:b]$1[reset]"
        },
        params: {
          rx: /(\|.+?\|)/,
          replacement: "[f:magenta:b]$1[reset]"
        },
        regex: {
          rx: /(r".*?"[img]{0,3})/,
          replacement: "[f:green:b]$1[reset]"
        },
        string: {
          rx: /((?<!r)".*?")/,
          replacement: "[f:green]$1[reset]"
        },
        keywords: {
          rx: /\b(end|if|else|elsif|return|next|continue|while|property)\b/,
          replacement: "[f:blue:b]$1[reset]"
        },
        reserved_words: {
          rx: /(?<=\b|\A)(self|true|yes|on|false|no|off|lambda?|lambda|defined?)(?=\b|\z)/,
          replacement: "[f:red]$1[reset]"
        },
        comment: {
          rx: /(\#[\s\S]+?)\z/,
          replacement: "[f:black:b]$1[reset]"
        }
      }

      # --- Template Helpers -----------------------------------------------------

      def highlight(line)
        new_line = line.dup
        if options[:syntax]
          if line =~ COMMENT
            new_line = "[f:black:b]#{line}"
          else
            HIGHLIGHT.each do |_, details|
              if line =~ details[:rx]
                new_line.gsub!(details[:rx]) do
                  new_text = details[:replacement].dup
                  Regexp.last_match[1..-1].each_with_index do |match, idx|
                    next if match.nil?
                    new_text.gsub!("$#{idx + 1}", match)
                  end
                  new_text
                end
              end
            end
          end
        end
        new_line
      end

      def escape(line)
        line.gsub(/(\[[fb]:.+?\])/) do
          "__ESC__#{$1}"
        end
      end

      def write_edit_menu
        unless buffer
          prop = editing_object.send(editing_property)
          prop ||= ""
          self.buffer = prop.lines
        end
        padding = buffer.length.to_s.length
        display_lines = buffer.each_with_index.map do |line, idx|
          "[reset]#{idx.next.to_s.rjust(padding)}) #{highlight(escape(line))}"
        end
        text = Helpers::View.render("responder.editor.main", {display_lines: display_lines.join, property: editing_property})
        write_without_prompt_or_newline(text)
      end

      # --- Helpers --------------------------------------------------------------

      def editing_object
        internal_state[:object]
      end

      def editing_property
        internal_state[:property]
      end

      def buffer
        internal_state[:buffer]
      end

      def buffer=(new_buffer)
        internal_state[:buffer] = new_buffer
      end

      def unsaved_changes
        internal_state[:unsaved_changes]
      end

      def unsaved_changes=(value)
        internal_state[:unsaved_changes] = value
      end

      def options
        internal_state[:options]
      end

      def open_editor(object, property, opts = {}, &block)
        opts = default_open_editor_options.merge(opts)
        store_original_state(&block)
        change_input_state(:editor)
        self.internal_state = {
          object: object,
          property: property,
          options: opts,
          unsaved_changes: false
        }
        write_edit_menu
      end

      def default_open_editor_options
        {
          allow_colors: false,
          syntax: false
        }
      end

      # --- Responders -----------------------------------------------------------

      responders_for_mode :free_edit do
        parse_input_with(/\A.q\z/) do
          clear_mode
          write_edit_menu
        end

        parse_input_with(/\A(.*)\z/) do |input|
          buffer << input + "\n"
          self.unsaved_changes = true
          write_without_prompt_or_newline("[f:green]>> ")
        end
      end

      responders_for_mode :line_edit do
        parse_input_with(/\A(.*)\z/) do |input|
          idx = internal_state[:index]
          buffer[idx] = input + "\n"
          self.unsaved_changes = true
          internal_state.delete(:index)
          clear_mode
          write_edit_menu
        end
      end

      responders_for_mode :clear do
        parse_input_with(/\A(yes|y|no|n)\z/i) do |answer|
          if answer =~ /y/i
            self.buffer = []
            self.unsaved_changes = true
            write_edit_menu
          end
          clear_mode
          write_edit_menu
        end

        parse_input_with(/\A.*\z/) do
          write_without_prompt("[f:green]Are you sure you want to clear the entire buffer [f:green:b](y/n)[reset][f:green]?")
        end
      end

      responders_for_mode :delete_line do
        parse_input_with(/\A(yes|y|no|n)\z/i) do |answer|
          if answer =~ /y/i
            idx = internal_state[:index]
            buffer.delete_at(idx)
            self.unsaved_changes = true
          end
          clear_mode
          internal_state.delete(:index)
          write_edit_menu
        end

        parse_input_with(/\A.*\z/) do
          idx = internal_state[:index]
          write_without_prompt("[f:green]Are you sure you want to delete line ##{idx.next} from the buffer [f:green:b](y/n)[reset][f:green]?")
        end
      end

      responders_for_mode :insert_line do
        parse_input_with(/\A(.+)\z/) do |new_line|
          idx = internal_state.delete(:index)
          buffer.insert(idx, new_line + "\n")
          clear_mode
          write_edit_menu
        end
      end

      responders_for_mode :exit do
        parse_input_with(/\A(yes|y|no|n)\z/i) do |answer|
          if answer =~ /y/i
            restore_original_state
          else
            clear_mode
            write_edit_menu
          end
        end

        parse_input_with(/\A.*\z/) do
          write_without_prompt("[f:green]Are you sure you wish to exit without saving [f:green:b](y/n)[reset][f:green]?")
        end
      end

      parse_input_with(/\A\.\z/) do
        change_mode(:free_edit)
        write_without_prompt_or_newline("[f:green]>> ")
      end

      parse_input_with(/\Aq\z/) do
        if unsaved_changes
          change_mode(:exit)
          write_without_prompt("[f:green]Are you sure you wish to exit without saving [f:green:b](y/n)[reset][f:green]?")
        else
          restore_original_state
        end
      end

      parse_input_with(/\Ah\z/) do
        render("responder.editor.help")
      end

      parse_input_with(/\A\.(\d+)\z/) do |line_idx|
        idx = line_idx.to_i - 1
        if idx < buffer.length
          change_mode(:line_edit)
          internal_state[:index] = idx
          write_without_prompt("[f:green]Current:")
          text = buffer[idx]
          text = text.purge_colors unless options[:allow_colors] || options[:syntax]
          text = highlight(escape(text)) if options[:syntax]
          write_without_prompt(text)
          write_without_prompt_or_newline("\n[f:green]>> ")
        else
          write_without_prompt("[f:yellow:b]There buffer isnt that big!")
          write_edit_menu
        end
      end

      parse_input_with(/\Ad(\d+)\z/) do |line_idx|
        idx = line_idx.to_i - 1
        internal_state[:index] = idx
        change_mode(:delete_line)
        write_without_prompt("[f:green]Are you sure you want to delete line ##{idx.next} from the buffer [f:green:b](y/n)[reset][f:green]?")
      end

      parse_input_with(/\Ai(\d+)\z/) do |line_idx|
        idx = line_idx.to_i - 1
        internal_state[:index] = idx
        change_mode(:insert_line)
        write_without_prompt_or_newline("[f:green]>> ")
      end

      parse_input_with(/\Ac\z/) do
        change_mode(:clear)
        write_without_prompt("[f:green]Are you sure you want to clear the entire buffer [f:green:b](y/n)[reset][f:green]?")
      end

      parse_input_with(/\Aw\z/) do
        self.unsaved_changes = false
        text = buffer.join("")
        text = text.purge_colors unless options[:allow_colors] || options[:syntax]
        editing_object.update_attribute(editing_property, text)
        write_without_prompt("[f:green]The buffer has been saved!")
      end

      parse_input_with(/\A.*\z/) do
        write_edit_menu
      end
    end
  end
end

Input::Manager.register_responder(:editor, Input::Responder::Editor)