class EditorResponder < InputResponder
  # --- Template Helpers -----------------------------------------------------

  def send_edit_menu
    if buffer
      buffer
    else
      prop = editing_object.send(editing_property)
      prop ||= ""
      self.buffer = prop.lines
    end
    padding = buffer.length.to_s.length
    display_lines = []
    buffer.each_with_index do |line, idx|
      display_lines << "#{idx.next.to_s.rjust(padding)}) #{line}"
    end
    display_lines = display_lines.join("")
    header = "==== Edit #{editing_property.to_s.capitalize} "
    header += ("=" * (79 - header.length))
    text = <<-TEXT

[f:white:b]#{header}[reset]

#{display_lines}
[reset][f:green]
  | [f:white:b][c] [reset][f:green]Clear Buffer | [f:white:b][.#] [reset][f:green]Edit Line      | [f:white:b][d#] [reset][f:green]Delete Line |
  | [f:white:b][.] [reset][f:green]Free Edit    | [f:white:b][.q] [reset][f:green]Quit Free Edit |                  |
  | [f:white:b][w] [reset][f:green]Save Changes | [f:white:b][e]  [reset][f:green]Exit Editor    | [f:white:b][h]  [reset][f:green]Help        |

Enter option >>
    TEXT
    send_no_prompt_or_newline(text)
  end

  def send_editor_help
    text = <<-TEXT
[f:white:b]
==== Editor Help ==============================================================

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
[f:white:b]
===============================================================================

    TEXT
    send_no_prompt_or_newline(text)
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

  def restore_original_state
    restore_state = internal_state[:restore_state]
    change_input_state(restore_state[:input_state])
    self.internal_state = restore_state[:internal_state]
    restore_state[:restore_cb].call(connection)
  end

  def open_editor(object, property, opts = {}, &block)
    opts = default_open_editor_options.merge(opts)
    new_state = {
      object: object,
      property: property,
      options: opts,
      unsaved_changes: false,
      restore_state: {
        input_state: input_state,
        internal_state: internal_state,
        restore_cb: block
      }
    }
    change_input_state(:editor)
    self.internal_state = new_state
    send_edit_menu
  end

  def default_open_editor_options
    {allow_colors: false}
  end

  # --- Responders -----------------------------------------------------------

  responders_for_mode :free_edit do
    parse_input_with(/\A.q\z/) do
      clear_mode
      send_edit_menu
    end

    parse_input_with(/\A(.+)\z/) do |input|
      buffer << input + "\n"
      self.unsaved_changes = true
      send_no_prompt_or_newline("[f:green]>> ")
    end
  end

  responders_for_mode :line_edit do
    parse_input_with(/\A(.*)\z/) do |input|
      idx = internal_state[:index]
      buffer[idx] = input + "\n"
      self.unsaved_changes = true
      internal_state.delete(:index)
      clear_mode
      send_edit_menu
    end
  end

  responders_for_mode :clear do
    parse_input_with(/\A(yes|y|no|n)\z/i) do |answer|
      if answer =~ /y/i
        self.buffer = []
        self.unsaved_changes = true
        send_edit_menu
      end
      clear_mode
      send_edit_menu
    end

    parse_input_with(/\A.*\z/) do
      send_no_prompt("[f:green]Are you sure you want to clear the entire buffer [f:green:b](y/n)[reset][f:green]?")
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
      send_edit_menu
    end

    parse_input_with(/\A.*\z/) do
      idx = internal_state[:index]
      send_no_prompt("[f:green]Are you sure you want to delete line ##{idx.next} from the buffer [f:green:b](y/n)[reset][f:green]?")
    end
  end

  responders_for_mode :exit do
    parse_input_with(/\A(yes|y|no|n)\z/i) do |answer|
      if answer =~ /y/i
        restore_original_state
      else
        clear_mode
        send_edit_menu
      end
    end

    parse_input_with(/\A.*\z/) do
      send_no_prompt("[f:green]Are you sure you wish to exit without saving [f:green:b](y/n)[reset][f:green]?")
    end
  end

  parse_input_with(/\A\.\z/) do
    change_mode(:free_edit)
    send_no_prompt_or_newline("[f:green]>> ")
  end

  parse_input_with(/\Ae\z/) do
    if unsaved_changes
      change_mode(:exit)
      send_no_prompt("[f:green]Are you sure you wish to exit without saving [f:green:b](y/n)[reset][f:green]?")
    else
      restore_original_state
    end
  end

  parse_input_with(/\Ah\z/) do
    send_editor_help
  end

  parse_input_with(/\A\.(\d+)\z/) do |line_idx|
    idx = line_idx.to_i - 1
    if idx < conn.internal_state[:buffer].length
      change_mode(:line_edit)
      internal_state[:index] = idx
      send_no_prompt("[f:green]Current:")
      send_no_prompt(buffer[idx])
      send_no_prompt_or_newline("\n[f:green]>> ")
    else
      send_no_prompt("[f:yellow:b]There buffer isnt that big!")
      send_edit_menu
    end
  end

  parse_input_with(/\Ad(\d+)\z/) do |line_idx|
    idx = line_idx.to_i - 1
    internal_state[:index] = idx
    change_mode(:delete_line)
    send_no_prompt("[f:green]Are you sure you want to delete line ##{idx.next} from the buffer [f:green:b](y/n)[reset][f:green]?")
  end

  parse_input_with(/\Ac\z/) do
    change_mode(:clear)
    send_no_prompt("[f:green]Are you sure you want to clear the entire buffer [f:green:b](y/n)[reset][f:green]?")
  end

  parse_input_with(/\Aw\z/) do
    self.unsaved_changes = false
    text = buffer.join("")
    text.purge_colors unless options[:allow_colors]
    editing_object.update_attribute(editing_property, text)
    send_no_prompt("[f:green]The buffer has been saved!")
  end

  parse_input_with(/\A.*\z/) do
    send_edit_menu
  end
end

InputManager.add_responder(:editor, EditorResponder)