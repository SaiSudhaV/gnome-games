// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/display-box.ui")]
private class Games.DisplayBox : Gtk.Bin {
	public signal void back ();
	public signal void snapshots_hidden ();
	public signal void restart ();

	private bool _is_fullscreen;
	public bool is_fullscreen {
		get { return _is_fullscreen; }
		set {
			_is_fullscreen = value;

			// A top margin is added to the savestates list in fullscreen mode such that
			// the fullscreen header bar doesn't cover the savestates menu
			savestates_list.set_margin (value ? fullscreen_header_bar_height : 0);
		}
	}

	public bool is_showing_snapshots { get; set; }

	public DisplayHeaderBar header_bar {
		get { return fullscreen_header_bar; }
	}

	private Runner _runner;
	public Runner runner {
		get { return _runner; }
		set {
			if (runner != null)
				runner.new_savestate_created.disconnect (flash_box.flash);

			stack.visible_child = display_overlay;

			_runner = value;
			remove_display ();
			header_bar.runner = runner;

			if (runner == null)
				return;

			var display = runner.get_display ();
			set_display (display);

			savestates_list.runner = value;

			runner.new_savestate_created.connect (flash_box.flash);
		}
	}

	public bool can_fullscreen { get; set; }
	public string game_title { get; set; }

	[GtkChild]
	private Gtk.Stack stack;
	[GtkChild]
	private ErrorDisplay error_display;
	[GtkChild]
	private Gtk.Overlay display_overlay;
	[GtkChild]
	private DisplayBin display_bin;
	[GtkChild]
	private FullscreenBox fullscreen_box;
	[GtkChild]
	private DisplayHeaderBar fullscreen_header_bar;
	[GtkChild]
	private FlashBox flash_box;
	[GtkChild]
	private SavestatesList savestates_list;

	private int fullscreen_header_bar_height;

	construct {
		bind_property ("can-fullscreen", header_bar,
		               "can-fullscreen", BindingFlags.BIDIRECTIONAL);
	}

	public void display_running_game_failed (Game game, string error_message) {
		stack.visible_child = error_display;
		error_display.running_game_failed (game, error_message);
	}

	public void display_game_crashed (Game game, string error_message) {
		stack.visible_child = error_display;
		is_showing_snapshots = false;
		error_display.game_crashed (game, error_message);
	}

	[GtkCallback]
	public void block_autohide_changed () {
		fullscreen_box.autohide = !fullscreen_header_bar.is_menu_open && !is_showing_snapshots;
	}

	[GtkCallback]
	private void on_fullscreen_header_bar_back () {
		back ();
	}

	private void set_display (Gtk.Widget display) {
		remove_display ();
		display_bin.add (display);
		display.visible = true;
	}

	private void remove_display () {
		var child = display_bin.get_child ();
		if (child != null)
			display_bin.remove (child);
	}

	public bool on_key_press_event (uint keyval, Gdk.ModifierType state) {
		if (!get_mapped ())
			return false;

		if (runner == null)
			return false;

		if (is_showing_snapshots)
			return savestates_list.on_key_press_event (keyval, state);

		return runner.key_press_event (keyval, state);
	}

	public bool gamepad_button_press_event (Manette.Event event) {
		if (!get_mapped ())
			return false;

		if (runner == null)
			return false;

		uint16 button;
		if (!event.get_button (out button))
			return false;

		return runner.gamepad_button_press_event (button);
	}

	[GtkCallback]
	private void on_fullscreen_header_bar_size_allocated (Gtk.Allocation allocation) {
		fullscreen_header_bar_height = allocation.height;
	}

	[GtkCallback]
	private void on_savestates_list_size_allocate (Gtk.Allocation allocation) {
		display_bin.horizontal_offset = -allocation.width / 2;
	}

	[GtkCallback]
	private void on_snapshots_hidden () {
		snapshots_hidden ();
	}
}
