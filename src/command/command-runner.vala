// This file is part of GNOME Games. License: GPL-3.0+.

public class Games.CommandRunner : Object, Runner {
	public bool can_fullscreen {
		get { return false; }
	}

	public bool can_quit_safely {
		get { return true; }
	}

	public bool can_resume {
		get { return false; }
	}

	public MediaSet? media_set {
		get { return null; }
	}

	public InputMode input_mode {
		get { return InputMode.NONE; }
		set { }
	}

	private string[] args;

	public CommandRunner (string[] args) {
		this.args = args;
	}

	public bool try_init_phase_one (out string error_message) {
		if (args.length > 0) {
			error_message = "";

			return true;
		}

		debug ("Invalid command: it doesn’t have any argument.");
		error_message = _("The game doesn’t have a valid command.");

		return false;
	}

	public Gtk.Widget get_display () {
		return new RemoteDisplay ();
	}

	public Gtk.Widget? get_extra_widget () {
		return null;
	}

	public void start () throws Error {
		string? working_directory = null;
		string[]? envp = null;
		var flags = SpawnFlags.SEARCH_PATH;
		SpawnChildSetupFunc? child_setup = null;
		Pid pid;

		string[] command = {};
		if (Application.is_running_in_flatpak ())
			command = { "flatpak-spawn", "--host" };
		foreach (var arg in args)
			command += arg;

		try {
			var result = Process.spawn_async (
				working_directory, command, envp, flags, child_setup, out pid);
			if (!result)
				throw new CommandError.EXECUTION_FAILED (_("Couldn’t run “%s”: execution failed."), args[0]);
		}
		catch (SpawnError e) {
			warning ("%s\n", e.message);
		}
	}

	public void resume () throws Error {
	}

	public void pause () {
	}

	public void stop () {
	}

	public void attempt_create_savestate () {
	}

	public InputMode[] get_available_input_modes () {
		return { };
	}

	public bool key_press_event (Gdk.EventKey event) {
		return false;
	}

	public bool gamepad_button_press_event (uint16 button) {
		return false;
	}
}
