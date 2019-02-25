// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/preferences-sidebar-item.ui")]
private class Games.PreferencesSidebarItem : Gtk.ListBoxRow {
	[GtkChild]
	private Gtk.Label label;

	private PreferencesPage _preferences_page;
	public PreferencesPage preferences_page {
		get { return _preferences_page; }
		construct {
			_preferences_page = value;
			label.label = value.title;
		}
	}

	public PreferencesSidebarItem (PreferencesPage preferences_page) {
		Object (preferences_page : preferences_page);
	}
}
