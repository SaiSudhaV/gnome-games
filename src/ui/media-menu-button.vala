// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/media-menu-button.ui")]
private class Games.MediaMenuButton : Gtk.Bin {
	[GtkChild]
	private Gtk.Image media_image;
	[GtkChild]
	private Gtk.Popover popover;
	[GtkChild]
	private Gtk.ListBox list_box;

	public bool active { get; set; }

	private MediaSet _media_set;
	public MediaSet media_set {
		get { return _media_set; }
		set {
			if (media_set_changed_id != 0) {
				_media_set.disconnect (media_set_changed_id);
				media_set_changed_id = 0;
			}

			_media_set = value;

			if (_media_set != null) {
				media_set_changed_id = _media_set.notify["selected-media-number"].connect (reset_media);
				media_image.set_from_icon_name (media_set.icon_name, Gtk.IconSize.BUTTON);
			}

			reset_media ();
		}
	}

	private ulong media_set_changed_id = 0;

	private void reset_media () {
		remove_media ();
		update_media ();

		visible = (media_set != null && media_set.get_size () > 1);
	}

	private void update_media () {
		var media_number = 0;

		if (_media_set == null)
			return;

		_media_set.foreach_media ((media) => {
			string media_name;
			if (media.title == null)
				media_name = _("Media %d").printf (media_number);
			else {
				try {
					media_name = media.title.get_title ();
				}
				catch (Error e) {
					warning (e.message);

					media_name = "";
				}
			}

			var checkmark_item = new CheckmarkItem (media_name);
			var media_has_uris = (media.get_uris ().length != 0);
			checkmark_item.sensitive = media_has_uris;
			var is_current_media = (_media_set.selected_media_number == media_number);
			checkmark_item.checkmark_visible = is_current_media;
			list_box.add (checkmark_item);

			media_number++;
		});
	}

	private void remove_media () {
		list_box.foreach ((child) => child.destroy ());
	}

	[GtkCallback]
	private void on_row_activated (Gtk.ListBoxRow activated_row) {
		var media_number = activated_row.get_index ();
		_media_set.selected_media_number = media_number;

		var i = 0;
		var row = list_box.get_row_at_index (i);
		while (row != null) {
			var checkmark_item = row as CheckmarkItem;
			checkmark_item.checkmark_visible = (i == media_number);

			row = list_box.get_row_at_index (++i);
		}

		popover.popdown ();
	}
}
