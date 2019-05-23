// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/collection-header-bar.ui")]
private class Games.CollectionHeaderBar : Gtk.Stack {
	public bool search_mode { get; set; }
	private Gtk.Stack _viewstack;
	public Gtk.Stack viewstack {
		get { return _viewstack; }
		set {
			if (viewstack_child_changed_id != 0) {
				viewstack.disconnect (viewstack_child_changed_id);
				viewstack_child_changed_id = 0;
			}

			_viewstack = value;
			view_switcher.stack = _viewstack;

			if (viewstack != null)
				viewstack_child_changed_id = viewstack.notify["visible-child"].connect (update_title);
		}
	}

	private bool _is_collection_empty;
	public bool is_collection_empty {
		get { return _is_collection_empty; }
		set {
			_is_collection_empty = value;
			title_squeezer.set_child_enabled (view_switcher, !value);
			search.sensitive = !_is_collection_empty;
			update_adaptive_state ();
		}
	}

	private AdaptiveState _adaptive_state;
	public AdaptiveState adaptive_state {
		get { return _adaptive_state; }
		construct {
			_adaptive_state = value;
			adaptive_state.notify["is-folded"].connect (update_folded);
			adaptive_state.notify["is-subview-open"].connect (update_subview);
			adaptive_state.notify["subview-title"].connect (update_subview_title);
		}
	}

	[GtkChild]
	private Gtk.HeaderBar subview_header_bar;
	[GtkChild]
	private Hdy.Squeezer title_squeezer;
	[GtkChild]
	private Gtk.Label title_label;
	[GtkChild]
	private Hdy.ViewSwitcher view_switcher;
	[GtkChild]
	private Gtk.ToggleButton search;
	[GtkChild]
	private Gtk.ToggleButton search_subview;

	private Binding search_binding;
	private Binding search_subview_binding;

	private ulong viewstack_child_changed_id;

	construct {
		search_binding = bind_property ("search-mode", search, "active",
		                                BindingFlags.BIDIRECTIONAL);
		search_subview_binding = bind_property ("search-mode", search_subview,
		                                        "active", BindingFlags.BIDIRECTIONAL);
	}

	public CollectionHeaderBar (AdaptiveState adaptive_state) {
		Object (adaptive_state: adaptive_state);
	}

	[GtkCallback]
	private void on_squeezer_visible_child_changed () {
		update_adaptive_state ();
	}

	private void update_adaptive_state () {
		bool showing_title = title_squeezer.visible_child != view_switcher;
		adaptive_state.is_showing_bottom_bar = showing_title && !is_collection_empty;

		update_title ();
	}

	private void update_title () {
		var title = _("Games");

		if (!is_collection_empty) {
			var child = viewstack.visible_child;

			viewstack.child_get (child, "title", out title, null);
		}

		title_label.label = title;
	}

	private void update_subview () {
		bool show_subview = adaptive_state.is_subview_open && adaptive_state.is_folded;
		visible_child_name = show_subview ? "subview" : "main";
	}

	private void update_folded () {
		bool show_subview = adaptive_state.is_subview_open && adaptive_state.is_folded;

		// FIXME: have a transition here. Crossfade doens't work well at the moment
		set_visible_child_full (show_subview ? "subview" : "main", Gtk.StackTransitionType.NONE);
	}

	private void update_subview_title () {
		subview_header_bar.title = adaptive_state.subview_title;
	}

	[GtkCallback]
	private void on_subview_back_clicked () {
		adaptive_state.is_subview_open = false;
	}
}
