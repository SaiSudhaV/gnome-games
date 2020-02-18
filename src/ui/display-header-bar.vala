// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/display-header-bar.ui")]
private class Games.DisplayHeaderBar : Gtk.Bin {
	public signal void back ();

	private ulong extra_widget_notify_block_autohide_id;

	[GtkChild]
	private MediaMenuButton media_button;

	public string game_title { get; set; }
	public bool show_title_buttons { get; set; default = true; }

	public bool can_fullscreen { get; set; }
	public bool is_fullscreen { get; set; }
	public bool is_showing_snapshots { get; set; }
	public bool is_menu_open { get; private set; }

	public MediaSet? media_set {
		set { media_button.media_set = value; }
	}

	[GtkChild]
	private InputModeSwitcher input_mode_switcher;
	private Runner _runner;
	public Runner runner {
		get { return _runner; }
		set {
			_runner = value;
			input_mode_switcher.runner = value;

			secondary_menu_button.visible = runner != null && runner.is_integrated;

			if (runner != null)
				extra_widget = runner.get_extra_widget ();
			else
				extra_widget = null;
		}
	}

	private HeaderBarWidget _extra_widget;
	private HeaderBarWidget extra_widget {
		get { return _extra_widget; }
		set {
			if (extra_widget == value)
				return;

			if (extra_widget != null) {
				extra_widget.disconnect (extra_widget_notify_block_autohide_id);
				ingame_header_bar.remove (extra_widget);
				extra_widget_notify_block_autohide_id = 0;
			}

			_extra_widget = value;

			if (extra_widget != null) {
				extra_widget_notify_block_autohide_id = extra_widget.notify["block-autohide"].connect (on_menu_state_changed);
				ingame_header_bar.pack_end (extra_widget);
			}
		}
	}

	[GtkChild]
	private Gtk.Stack stack;
	[GtkChild]
	private Gtk.HeaderBar ingame_header_bar;
	[GtkChild]
	private Gtk.Button fullscreen;
	[GtkChild]
	private Gtk.Button restore;
	[GtkChild]
	private Gtk.MenuButton secondary_menu_button;
	[GtkChild]
	private Gtk.HeaderBar savestates_header_bar;

	private Settings settings;

	construct {
		settings = new Settings ("org.gnome.Games");
	}

	[GtkCallback]
	private void on_fullscreen_changed () {
		fullscreen.visible = can_fullscreen && !is_fullscreen;
		restore.visible = can_fullscreen && is_fullscreen;
	}

	[GtkCallback]
	private void on_back_clicked () {
		back ();
	}

	[GtkCallback]
	private void on_fullscreen_clicked () {
		is_fullscreen = true;
		settings.set_boolean ("fullscreen", true);
	}

	[GtkCallback]
	private void on_menu_state_changed () {
		is_menu_open = media_button.active || secondary_menu_button.active || extra_widget.block_autohide;
	}

	[GtkCallback]
	private void on_restore_clicked () {
		is_fullscreen = false;
		settings.set_boolean ("fullscreen", false);
	}

	[GtkCallback]
	private void on_showing_snapshots_changed () {
		if (is_showing_snapshots)
			stack.visible_child = savestates_header_bar;
		else
			stack.visible_child = ingame_header_bar;
	}
}
