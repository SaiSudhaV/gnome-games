// This file is part of GNOME Games. License: GPL-3.0+.

private class Games.GameThumbnail : Gtk.DrawingArea {
	private const double EMBLEM_SCALE = 0.125;
	private const double ICON_SCALE = 0.75;

	private ulong cover_changed_id;
	private Uid uid;
	private Icon icon;
	private Cover cover;

	private Game _game;
	public Game game {
		get { return _game; }
		set {
			if (_game == value)
				return;

			if (cover != null)
				cover.disconnect (cover_changed_id);

			_game = value;
			uid = game.get_uid ();
			icon = game.get_icon ();
			cover = game.get_cover ();

			try_load_cover = true;

			if (cover != null)
				cover_changed_id = cover.changed.connect (() => {
					try_load_cover = true;
					queue_draw ();
				});

			queue_draw ();
		}
	}

	private Gdk.Pixbuf? cover_pixbuf;
	private bool loading_cover;
	private bool try_load_cover;
	private int last_size;

	public struct DrawingContext {
		Cairo.Context cr;
		Gtk.StyleContext style;
		Gtk.StateFlags state;
		int width;
		int height;
	}

	construct {
		try_load_cover = true;
	}

	static construct {
		set_css_name ("gamesgamethumbnail");
	}

	public override Gtk.SizeRequestMode get_request_mode () {
		return Gtk.SizeRequestMode.HEIGHT_FOR_WIDTH;
	}

	public override void get_preferred_height_for_width (int width, out int minimum_height, out int natural_height) {
		minimum_height = natural_height = width;
	}

	public override bool draw (Cairo.Context cr) {
		var style = get_style_context ();
		var state = get_state_flags ();
		var width = get_allocated_width ();
		var height = get_allocated_height ();

		DrawingContext context = {
			cr, style, state, width, height
		};

		if (icon == null)
			return false;

		if (cover == null)
			return false;

		var drawn = false;

		drawn = draw_cover (context);

		if (!drawn)
			drawn = draw_icon (context);

		// Draw the default thumbnail if no thumbnail have been drawn
		if (!drawn)
			draw_default (context);

		return true;
	}

	public bool draw_icon (DrawingContext context) {
		var g_icon = icon.get_icon ();
		if (g_icon == null)
			return false;

		var pixbuf = get_scaled_icon (context, g_icon, ICON_SCALE);
		if (pixbuf == null)
			return false;

		draw_background (context);
		draw_pixbuf (context, pixbuf);
		draw_border (context);

		return true;
	}

	public bool draw_cover (DrawingContext context) {
		var pixbuf = get_scaled_cover (context);
		if (pixbuf == null)
			return false;

		var border_radius = (int) context.style.get_property (Gtk.STYLE_PROPERTY_BORDER_RADIUS, context.state);
		border_radius = border_radius.clamp (0, int.max (context.width / 2, context.height / 2));

		context.cr.set_source_rgb (0, 0, 0);
		rounded_rectangle (context.cr, 0.5, 0.5, context.width - 1, context.height - 1, border_radius);
		context.cr.fill ();
		draw_pixbuf (context, pixbuf);
		draw_border (context);

		return true;
	}

	public void draw_default (DrawingContext context) {
		draw_background (context);
		draw_emblem_icon (context, Config.APPLICATION_ID + "-symbolic", EMBLEM_SCALE);
		draw_border (context);
	}

	private void draw_emblem_icon (DrawingContext context, string icon_name, double scale) {
		Gdk.Pixbuf? emblem = null;

		var color = context.style.get_color (context.state);

		var theme = Gtk.IconTheme.get_default ();
		var size = int.min (context.width, context.height) * scale * scale_factor;
		try {
			var icon_info = theme.lookup_icon (icon_name, (int) size, Gtk.IconLookupFlags.FORCE_SIZE);
			emblem = icon_info.load_symbolic (color);
		} catch (GLib.Error error) {
			warning (@"Unable to get icon “$icon_name”: $(error.message)");
			return;
		}

		if (emblem == null)
			return;

		double offset_x = context.width * scale_factor / 2.0 - emblem.width / 2.0;
		double offset_y = context.height * scale_factor / 2.0 - emblem.height / 2.0;

		context.cr.save ();
		context.cr.scale (1.0 / scale_factor, 1.0 / scale_factor);

		Gdk.cairo_set_source_pixbuf (context.cr, emblem, offset_x, offset_y);
		context.cr.paint ();

		context.cr.restore ();
	}

	private Gdk.Pixbuf? get_scaled_icon (DrawingContext context, GLib.Icon? icon, double scale) {
		if (icon == null)
			return null;

		var theme = Gtk.IconTheme.get_default ();
		var lookup_flags = Gtk.IconLookupFlags.FORCE_SIZE | Gtk.IconLookupFlags.FORCE_REGULAR;
		var size = int.min (context.width, context.height) * scale * scale_factor;
		var icon_info = theme.lookup_by_gicon (icon, (int) size, lookup_flags);

		if (icon_info == null)
			return null;

		try {
			return icon_info.load_icon ();
		}
		catch (Error e) {
			warning (@"Couldn’t load the icon: $(e.message)\n");
			return null;
		}
	}

	private Gdk.Pixbuf? get_scaled_cover (DrawingContext context) {
		var size = int.min (context.width, context.height) * scale_factor;

		if (size != last_size) {
			cover_pixbuf = null;
			try_load_cover = true;
		}

		if (!try_load_cover)
			return cover_pixbuf;

		var loader = Application.get_default ().get_cover_loader ();

		last_size = size;

		try_load_cover = false;
		loading_cover = true;
		loader.fetch_cover (game, size, (s, pixbuf) => {
			if (s != last_size) {
				cover_pixbuf = null;
				try_load_cover = true;
			} else
			if (pixbuf != null)
				cover_pixbuf = pixbuf;

			loading_cover = false;
			queue_draw ();
		});

		return cover_pixbuf;
	}

	private void draw_pixbuf (DrawingContext context, Gdk.Pixbuf pixbuf) {
		context.cr.save ();
		context.cr.scale (1.0 / scale_factor, 1.0 / scale_factor);

		var mask = get_mask (context);

		var x_offset = (context.width * scale_factor - pixbuf.width) / 2;
		var y_offset = (context.height * scale_factor - pixbuf.height) / 2;

		Gdk.cairo_set_source_pixbuf (context.cr, pixbuf, x_offset, y_offset);
		context.cr.mask_surface (mask, 0, 0);

		context.cr.restore ();
	}

	private Cairo.Surface get_mask (DrawingContext context) {
		var mask = new Cairo.ImageSurface (Cairo.Format.A8, context.width * scale_factor, context.height * scale_factor);

		var border_radius = (int) context.style.get_property (Gtk.STYLE_PROPERTY_BORDER_RADIUS, context.state);
		border_radius = border_radius.clamp (0, int.max (context.width / 2, context.height / 2));

		var cr = new Cairo.Context (mask);
		cr.scale (scale_factor, scale_factor);
		cr.set_source_rgb (0, 0, 0);
		rounded_rectangle (cr, 0.5, 0.5, context.width - 1, context.height - 1, border_radius);
		cr.fill ();

		return mask;
	}

	private void draw_background (DrawingContext context) {
		context.style.render_background (context.cr, 0.0, 0.0, context.width, context.height);
	}

	private void draw_border (DrawingContext context) {
		context.style.render_frame (context.cr, 0.0, 0.0, context.width, context.height);
	}

	private void rounded_rectangle (Cairo.Context cr, double x, double y, double width, double height, double radius) {
		const double ARC_0 = 0;
		const double ARC_1 = Math.PI * 0.5;
		const double ARC_2 = Math.PI;
		const double ARC_3 = Math.PI * 1.5;

		cr.new_sub_path ();
		cr.arc (x + width - radius, y + radius,          radius, ARC_3, ARC_0);
		cr.arc (x + width - radius, y + height - radius, radius, ARC_0, ARC_1);
		cr.arc (x + radius,         y + height - radius, radius, ARC_1, ARC_2);
		cr.arc (x + radius,         y + radius,          radius, ARC_2, ARC_3);
		cr.close_path ();
	}
}
