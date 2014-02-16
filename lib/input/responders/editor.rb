module EditorHelpers
  LINE_EDIT_RX = /\.(\d+)/
  DELETE_LINE_RX = /d(\d+)/

  def self.edit_menu(conn)
    if conn.internal_state[:buffer]
      conn.internal_state[:buffer]
    else
      prop = conn.internal_state[:object].send(conn.internal_state[:property])
      prop ||= ""
      conn.internal_state[:buffer] = prop.lines
    end
    buffer = conn.internal_state[:buffer]
    padding = buffer.length.to_s.length
    display_lines = []
    buffer.each_with_index do |line, idx|
      display_lines << "#{idx.next.to_s.rjust(padding)}) #{line}"
    end
    display_lines = display_lines.join("")
    header = "==== Edit #{conn.internal_state[:property].to_s.capitalize} "
    header += ("=" * (79 - header.length))
    text = <<-TEXT

[f:white:b]#{header}[reset]

#{display_lines}

           [reset][f:green][.] Free Edit    | [.#] Edit Line      | [d#] Delete Line
           [w] Save Changes | [e]  Exit Editor    | [h]  Help
           [c] Clear Buffer | [.q] Quit Free Edit

Enter option >>
    TEXT
    conn.send_text(text, newline: false, prompt: false)
  end

  def self.editor_help(conn)
    text = <<-TEXT
[f:white:b]==== Editor Help =====================================================

[reset][f:green][[f:red].[f:green]]  Free Edit - [f:white]Begin editing at the end of the buffer. Every new line is
                appended.

[f:green][[f:red].q[f:green]] Quit Free Edit - [f:white]Exit Free Edit mode. Does nothing unless in Free Edit.

[f:green][[f:red].#[f:green]] Edit Line - [f:white]Edit the specified line in the buffer, replaces the current
                 line with new input.

[f:green][[f:red]d#[f:green]] Delete Line - [f:white]Delete the specified line from the buffer.

[f:green][[f:red]w[f:green]]  Save Changes - [f:white]Save the changes made to the buffer.

[f:green][[f:red]e[f:green]]  Exit Editor - [f:white]Exit edit mode. This does not save changes so it's good to
                   make sure that you save your changes before exiting.

[f:green][[f:red]h[f:green]]  Help - [f:white]Show this help page.

    TEXT
    conn.send_text(text, newline: false, prompt: false)
  end

  def self.restore(conn)
    restore_state = conn.internal_state[:restore_state]
    conn.input_state = restore_state[:input_state]
    conn.internal_state = restore_state[:internal_state]
    restore_state[:restore_cb].call(conn, restore_state[:internal_state])
  end

  def self.open_editor(conn, object, property, opts = {}, &block)
    opts = default_open_editor_options.merge(opts)
    new_state = {
      object: object,
      property: property,
      options: opts,
      unsaved: false,
      restore_state: {
        input_state: conn.input_state,
        internal_state: conn.internal_state,
        restore_cb: block
      }
    }
    conn.input_state = :editor
    conn.internal_state = new_state
    edit_menu(conn)
  end

  def self.default_open_editor_options
    {allow_colors: false}
  end
end

InputManager.respond_to :editor do
  parse_input_with(/(.*)/) do |conn, input|
    if conn.internal_state[:mode] == :free_edit
      if input == ".q"
        conn.internal_state.delete(:mode)
        EditorHelpers.edit_menu(conn)
      else
        conn.internal_state[:buffer] << input + "\n"
        conn.internal_state[:unsaved] = true
        conn.send_text("[f:green]>> ", newline: false, prompt: false)
      end
    elsif conn.internal_state[:mode] == :line_edit
      idx = conn.internal_state[:index]
      conn.internal_state[:buffer][idx] = input + "\n"
      conn.internal_state[:unsaved] = true
      conn.internal_state.delete(:index)
      conn.internal_state.delete(:mode)
      EditorHelpers.edit_menu(conn)
    elsif input.length > 0
      if [:clear, :delete_line, :exit].include?(conn.internal_state[:mode])
        if input =~ /\A(?:yes|y)\z/
          case conn.internal_state[:mode]
          when :clear
            conn.internal_state[:buffer] = []
            conn.internal_state[:unsaved] = true
            EditorHelpers.edit_menu(conn)
          when :delete_line
            idx = conn.internal_state[:index]
            conn.internal_state[:buffer].delete_at(idx)
            conn.internal_state[:unsaved] = true
            EditorHelpers.edit_menu(conn)
          when :exit
            EditorHelpers.restore(conn)
          end
          conn.internal_state.delete(:mode)
          conn.internal_state.delete(:index)
        elsif input =~ /\A(?:no|n)\z/
          conn.internal_state.delete(:mode)
          conn.internal_state.delete(:index)
          EditorHelpers.edit_menu(conn)
        else
          case conn.internal_state[:mode]
          when :clear
            conn.send_text("[f:green]Are you sure you want to clear the entire buffer [f:green:b](y/n)[reset][f:green]?", prompt: false)
          when :delete_line
            idx = conn.internal_state[:index]
            conn.send_text("[f:green]Are you sure you want to delete line ##{idx.next} from the buffer [f:green:b](y/n)[reset][f:green]?", prompt: false)
          when :exit
            conn.send_text("[f:green]Are you sure you wish to exit without saving [f:green:b](y/n)[reset][f:green]?", prompt: false)
          end
        end
      else
        if input == "e"
          if conn.internal_state[:unsaved]
            conn.internal_state[:mode] = :exit
            conn.send_text("[f:green]Are you sure you wish to exit without saving [f:green:b](y/n)[reset][f:green]?", prompt: false)
          else
            EditorHelpers.restore(conn)
          end
        elsif input == "h"
          EditorHelpers.editor_help(conn)
        elsif input == "."
          conn.internal_state[:mode] = :free_edit
          conn.send_text("[f:green]>> ", newline: false, prompt: false)
        elsif input =~ EditorHelpers::LINE_EDIT_RX
          idx = $1.to_i - 1
          if idx < conn.internal_state[:buffer].length
            conn.internal_state[:mode] = :line_edit
            conn.internal_state[:index] = idx
            conn.send_text("[f:green]Current:", prompt: false)
            conn.send_text(conn.internal_state[:buffer][idx], prompt: false)
            conn.send_text("\n[f:green]>> ", newline: false, prompt: false)
          else
            conn.sned_text("[f:yellow:b]There buffer isnt that big!", prompt: false)
            EditorHelpers.edit_menu(conn)
          end
        elsif input =~ EditorHelpers::DELETE_LINE_RX
          idx = $1.to_i - 1
          conn.internal_state[:index] = idx
          conn.internal_state[:mode] = :delete_line
          conn.send_text("[f:green]Are you sure you want to delete line ##{idx.next} from the buffer [f:green:b](y/n)[reset][f:green]?", prompt: false)
        elsif input == "c"
          conn.internal_state[:mode] = :clear
          conn.send_text("[f:green]Are you sure you want to clear the entire buffer [f:green:b](y/n)[reset][f:green]?", prompt: false)
        elsif input == "w"
          conn.internal_state[:unsaved] = false
          text = conn.internal_state[:buffer].join("")
          conn.internal_state[:object].update_attribute(conn.internal_state[:property], text)
          conn.send_text("[f:green]The buffer has been saved!", prompt: false)
        else
          EditorHelpers.edit_menu(conn)
        end
      end
    else
      EditorHelpers.edit_menu(conn)
    end
  end
end