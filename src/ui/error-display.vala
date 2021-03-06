// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/error-display.ui")]
private class Games.ErrorDisplay : Gtk.Box {
	[GtkChild]
	private Gtk.Label primary_label;
	[GtkChild]
	private Gtk.Label secondary_label;
	[GtkChild]
	private Gtk.Button restart_btn;

	public void running_game_failed (Game game, string message) {
		string title;
		if (game != null)
			title = _("Oops! Unable to run “%s”").printf (game.name);
		else
			title = _("Oops! Unable to run the game");

		set_labels (title, message);
		restart_btn.hide ();
	}

	public void game_crashed (Game game, string message) {
		var title = _("Oops! The game “%s” crashed unexpectedly").printf (game.name);

		set_labels (title, message);
		restart_btn.show ();
	}

	private void set_labels (string primary, string secondary) {
		primary_label.label = primary;
		secondary_label.label = secondary;
	}
}
