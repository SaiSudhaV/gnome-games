// This file is part of GNOME Games. License: GPL-3.0+.

public class Games.LocalCover : Object, Cover {
	private Uri uri;
	private bool resolved;
	private File? file;

	public LocalCover (Uri uri) {
		this.uri = uri;
	}

	public File? get_cover () {
		if (resolved)
			return file;

		resolved = true;

		string? cover_path;
		try {
			cover_path = get_cover_path ();
		}
		catch (Error e) {
			warning (e.message);

			return null;
		}

		if (cover_path == null)
			return null;

		file = File.new_for_path (cover_path);

		return file;
	}

	private string? get_cover_path () throws Error {
		var cover_path = get_sibling_cover_path ();
		if (cover_path != null && FileUtils.test (cover_path, FileTest.EXISTS))
			return cover_path;

		cover_path = get_directory_cover_path ();
		if (cover_path != null && FileUtils.test (cover_path, FileTest.EXISTS))
			return cover_path;

		return null;
	}

	private string get_basename_prefix (string basename) {
		var pos = basename.last_index_of_char ('.');

		if (pos < 0)
			return basename;

		return basename.substring (0, pos);
	}

	private string? get_sibling_cover_path () throws Error {
		var file = uri.to_file ();
		var parent = file.get_parent ();
		if (parent == null)
			return null;

		var basename = file.get_basename ();
		var prefix = get_basename_prefix (basename);

		string cover_path = null;
		var directory = new Directory (parent);
		var attributes = string.join (",", FileAttribute.STANDARD_NAME, FileAttribute.STANDARD_FAST_CONTENT_TYPE);
		directory.foreach (attributes, (sibling) => {
			var sibling_basename = sibling.get_name ();
			if (sibling_basename == basename)
				return false;

			var sibling_prefix = get_basename_prefix (sibling_basename);
			if (prefix != sibling_prefix)
				return false;

			var type = sibling.get_attribute_string (FileAttribute.STANDARD_FAST_CONTENT_TYPE);
			if (!type.has_prefix ("image"))
				return false;

			var sibling_file = parent.get_child (sibling_basename);
			cover_path = sibling_file.get_path ();

			return true;
		});

		return cover_path;
	}

	private string? get_directory_cover_path () throws Error {
		var file = uri.to_file ();
		var parent = file.get_parent ();
		if (parent == null)
			return null;

		string cover_path = null;
		var directory = new Directory (parent);
		var attributes = string.join (",", FileAttribute.STANDARD_NAME, FileAttribute.STANDARD_FAST_CONTENT_TYPE);
		directory.foreach (attributes, (sibbling) => {
			var sibbling_basename = sibbling.get_name ();
			if (!sibbling_basename.has_prefix ("cover.") &&
			    !sibbling_basename.has_prefix ("folder."))
				return false;

			var type = sibbling.get_attribute_string (FileAttribute.STANDARD_FAST_CONTENT_TYPE);
			if (!type.has_prefix ("image"))
				return false;

			var sibbling_file = parent.get_child (sibbling_basename);
			cover_path = sibbling_file.get_path ();

			return true;
		});

		return cover_path;
	}
}
