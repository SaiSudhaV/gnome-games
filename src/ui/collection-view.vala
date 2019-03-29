// This file is part of GNOME Games. License: GPL-3.0+.

private class Games.CollectionView : Object, UiView {
	private const string CONTRIBUTE_URI = "https://wiki.gnome.org/Apps/Games/Contribute";

	public signal void game_activated (Game game);

	private CollectionBox box;
	private CollectionHeaderBar header_bar;

	public Gtk.Widget content_box {
		get { return box; }
	}

	public Gtk.Widget title_bar {
		get { return header_bar; }
	}

	private bool _is_view_active;
	public bool is_view_active {
		get { return _is_view_active; }
		set {
			if (is_view_active == value)
				return;

			_is_view_active = value;

			if (!is_view_active)
				search_mode = false;

			konami_code.reset ();
		}
	}

	public Gtk.Window window { get; construct set; }

	private ListModel _collection;
	public ListModel collection {
		get { return _collection; }
		construct set {
			_collection = value;

			collection.items_changed.connect (() => {
				is_collection_empty = collection.get_n_items () == 0;
			});
			is_collection_empty = collection.get_n_items () == 0;
		}
	}

	public bool loading_notification { get; set; }
	public bool search_mode { get; set; }
	public bool is_collection_empty { get; set; }

	private Binding loading_notification_binding;
	private Binding box_search_binding;
	private Binding box_empty_collection_binding;
	private Binding header_bar_search_binding;
	private Binding header_bar_empty_collection_binding;

	private KonamiCode konami_code;

	construct {
		box = new CollectionBox (collection);
		header_bar = new CollectionHeaderBar ();
		box.game_activated.connect (game => {
			game_activated (game);
		});

		header_bar.viewstack = box.viewstack;
		is_collection_empty = true;

		loading_notification_binding = bind_property ("loading-notification", box,
		                                              "loading-notification",
		                                              BindingFlags.DEFAULT);

		box_search_binding = bind_property ("search-mode", box, "search-mode",
		                                    BindingFlags.BIDIRECTIONAL);
		header_bar_search_binding = bind_property ("search-mode", header_bar,
		                                           "search-mode",
		                                           BindingFlags.BIDIRECTIONAL);

		box_empty_collection_binding = bind_property ("is-collection-empty", box,
		                                              "is-collection-empty",
		                                              BindingFlags.BIDIRECTIONAL);
		header_bar_empty_collection_binding = bind_property ("is-collection-empty",
		                                                     header_bar,
		                                                     "is-collection-empty",
		                                                     BindingFlags.BIDIRECTIONAL);

		konami_code = new KonamiCode (window);
		konami_code.code_performed.connect (on_konami_code_performed);
	}

	public CollectionView (Gtk.Window window, ListModel collection) {
		Object (window: window, collection: collection);
	}

	public void show_error (string error_message) {
		box.show_error (error_message);
	}

	public bool on_button_pressed (Gdk.EventButton event) {
		return false;
	}

	public bool on_key_pressed (Gdk.EventKey event) {
		var default_modifiers = Gtk.accelerator_get_default_mod_mask ();

		if ((event.keyval == Gdk.Key.f || event.keyval == Gdk.Key.F) &&
		    (event.state & default_modifiers) == Gdk.ModifierType.CONTROL_MASK) {
			if (!search_mode)
				search_mode = true;

			return true;
		}

		return box.search_bar_handle_event (event);
	}

	public bool gamepad_button_press_event (Manette.Event event) {
		return window.is_active && box.gamepad_button_press_event (event);
	}

	public bool gamepad_button_release_event (Manette.Event event) {
		return window.is_active && box.gamepad_button_release_event (event);
	}

	public bool gamepad_absolute_axis_event (Manette.Event event) {
		return window.is_active && box.gamepad_absolute_axis_event (event);
	}

	private void on_konami_code_performed () {
		if (!is_view_active)
			return;

		try {
			Gtk.show_uri_on_window (window, CONTRIBUTE_URI, Gtk.get_current_event_time ());
		}
		catch (Error e) {
			critical (e.message);
		}
	}
}