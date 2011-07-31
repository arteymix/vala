/* gnome-desktop-2.0.vapi generated by vapigen, do not modify. */

[CCode (cprefix = "Gnome", lower_case_cprefix = "gnome_")]
namespace Gnome {
	[CCode (cheader_filename = "libgnomeui/gnome-ditem-edit.h")]
	public class DItemEdit : Gtk.Notebook, Atk.Implementor, Gtk.Buildable {
		[CCode (has_construct_function = false, type = "GtkWidget*")]
		public DItemEdit ();
		public void clear ();
		public unowned Gnome.DesktopItem get_ditem ();
		public unowned string get_icon ();
		public void grab_focus ();
		public bool load_uri (string uri) throws GLib.Error;
		public void set_directory_only (bool directory_only);
		public void set_ditem (Gnome.DesktopItem ditem);
		public void set_editable (bool editable);
		public void set_entry_type (string type);
		public virtual signal void changed ();
		public virtual signal void icon_changed ();
		public virtual signal void name_changed ();
	}
	[CCode (cheader_filename = "libgnome/gnome-desktop-item.h", ref_function = "gnome_desktop_item_ref", type_id = "GNOME_TYPE_DESKTOP_ITEM", unref_function = "gnome_desktop_item_unref")]
	[Compact]
	public class DesktopItem {
		[CCode (has_construct_function = false)]
		public DesktopItem ();
		public bool attr_exists (string attr);
		public void clear_localestring (string attr);
		public void clear_section (string section);
		public Gnome.DesktopItem copy ();
		public int drop_uri_list (string uri_list, Gnome.DesktopItemLaunchFlags flags) throws GLib.Error;
		public int drop_uri_list_with_env (string uri_list, Gnome.DesktopItemLaunchFlags flags, string[] envp) throws GLib.Error;
		public static GLib.Quark error_quark ();
		public bool exists ();
		public static unowned string find_icon (Gtk.IconTheme icon_theme, string icon, int desired_size, int flags);
		[CCode (has_construct_function = false)]
		public DesktopItem.from_basename (string basename, Gnome.DesktopItemLoadFlags flags) throws GLib.Error;
		[CCode (has_construct_function = false)]
		public DesktopItem.from_file (string file, Gnome.DesktopItemLoadFlags flags) throws GLib.Error;
		[CCode (has_construct_function = false)]
		public DesktopItem.from_string (string uri, string str, ssize_t length, Gnome.DesktopItemLoadFlags flags) throws GLib.Error;
		[CCode (has_construct_function = false)]
		public DesktopItem.from_uri (string uri, Gnome.DesktopItemLoadFlags flags) throws GLib.Error;
		public unowned string get_attr_locale (string attr);
		public bool get_boolean (string attr);
		public Gnome.DesktopItemType get_entry_type ();
		public Gnome.DesktopItemStatus get_file_status ();
		public unowned string get_icon (Gtk.IconTheme icon_theme);
		public unowned GLib.List get_languages (string attr);
		public unowned string get_localestring (string attr);
		public unowned string get_localestring_lang (string attr, string language);
		public unowned string get_location ();
		public unowned string get_string (string attr);
		[CCode (array_length = false, array_null_terminated = true)]
		public unowned string[] get_strings (string attr);
		public int launch (GLib.List file_list, Gnome.DesktopItemLaunchFlags flags) throws GLib.Error;
		public int launch_on_screen (GLib.List file_list, Gnome.DesktopItemLaunchFlags flags, Gdk.Screen screen, int workspace) throws GLib.Error;
		public int launch_with_env (GLib.List file_list, Gnome.DesktopItemLaunchFlags flags, string[] envp) throws GLib.Error;
		public bool save (string under, bool force) throws GLib.Error;
		public void set_boolean (string attr, bool value);
		public void set_entry_type (Gnome.DesktopItemType type);
		public void set_launch_time (uint32 timestamp);
		public void set_localestring (string attr, string value);
		public void set_localestring_lang (string attr, string language, string value);
		public void set_location (string location);
		public void set_location_file (string file);
		public void set_string (string attr, string value);
		public void set_strings (string attr, [CCode (array_length = false, array_null_terminated = true)] string[] strings);
	}
	[CCode (cheader_filename = "libgnomeui/gnome-hint.h")]
	public class Hint : Gtk.Dialog, Atk.Implementor, Gtk.Buildable {
		[CCode (has_construct_function = false, type = "GtkWidget*")]
		public Hint (string hintfile, string title, string background_image, string logo_image, string startupkey);
	}
	[CCode (cheader_filename = "libgnome/gnome-desktop-item.h", cprefix = "GNOME_DESKTOP_ITEM_ERROR_", has_type_id = false)]
	public enum DesktopItemError {
		NO_FILENAME,
		UNKNOWN_ENCODING,
		CANNOT_OPEN,
		NO_EXEC_STRING,
		BAD_EXEC_STRING,
		NO_URL,
		NOT_LAUNCHABLE,
		INVALID_TYPE
	}
	[CCode (cheader_filename = "libgnome/gnome-desktop-item.h", cprefix = "GNOME_DESKTOP_ITEM_ICON_NO_", has_type_id = false)]
	public enum DesktopItemIconFlags {
		KDE
	}
	[CCode (cheader_filename = "libgnome/gnome-desktop-item.h", cprefix = "GNOME_DESKTOP_ITEM_LAUNCH_", has_type_id = false)]
	public enum DesktopItemLaunchFlags {
		ONLY_ONE,
		USE_CURRENT_DIR,
		APPEND_URIS,
		APPEND_PATHS,
		DO_NOT_REAP_CHILD
	}
	[CCode (cheader_filename = "libgnome/gnome-desktop-item.h", cprefix = "GNOME_DESKTOP_ITEM_LOAD_", has_type_id = false)]
	public enum DesktopItemLoadFlags {
		ONLY_IF_EXISTS,
		NO_TRANSLATIONS
	}
	[CCode (cheader_filename = "libgnome/gnome-desktop-item.h", cprefix = "GNOME_DESKTOP_ITEM_", has_type_id = false)]
	public enum DesktopItemStatus {
		UNCHANGED,
		CHANGED,
		DISAPPEARED
	}
	[CCode (cheader_filename = "libgnome/gnome-desktop-item.h", cprefix = "GNOME_DESKTOP_ITEM_TYPE_", has_type_id = false)]
	public enum DesktopItemType {
		NULL,
		OTHER,
		APPLICATION,
		LINK,
		FSDEVICE,
		MIME_TYPE,
		DIRECTORY,
		SERVICE,
		SERVICE_TYPE
	}
	[CCode (cheader_filename = "libgnome/gnome-desktop-item.h")]
	public const string DESKTOP_ITEM_ACTIONS;
	[CCode (cheader_filename = "libgnome/gnome-desktop-item.h")]
	public const string DESKTOP_ITEM_CATEGORIES;
	[CCode (cheader_filename = "libgnome/gnome-desktop-item.h")]
	public const string DESKTOP_ITEM_COMMENT;
	[CCode (cheader_filename = "libgnome/gnome-desktop-item.h")]
	public const string DESKTOP_ITEM_DEFAULT_APP;
	[CCode (cheader_filename = "libgnome/gnome-desktop-item.h")]
	public const string DESKTOP_ITEM_DEV;
	[CCode (cheader_filename = "libgnome/gnome-desktop-item.h")]
	public const string DESKTOP_ITEM_DOC_PATH;
	[CCode (cheader_filename = "libgnome/gnome-desktop-item.h")]
	public const string DESKTOP_ITEM_ENCODING;
	[CCode (cheader_filename = "libgnome/gnome-desktop-item.h")]
	public const string DESKTOP_ITEM_EXEC;
	[CCode (cheader_filename = "libgnome/gnome-desktop-item.h")]
	public const string DESKTOP_ITEM_FILE_PATTERN;
	[CCode (cheader_filename = "libgnome/gnome-desktop-item.h")]
	public const string DESKTOP_ITEM_FS_TYPE;
	[CCode (cheader_filename = "libgnome/gnome-desktop-item.h")]
	public const string DESKTOP_ITEM_GENERIC_NAME;
	[CCode (cheader_filename = "libgnome/gnome-desktop-item.h")]
	public const string DESKTOP_ITEM_HIDDEN;
	[CCode (cheader_filename = "libgnome/gnome-desktop-item.h")]
	public const string DESKTOP_ITEM_ICON;
	[CCode (cheader_filename = "libgnome/gnome-desktop-item.h")]
	public const string DESKTOP_ITEM_MIME_TYPE;
	[CCode (cheader_filename = "libgnome/gnome-desktop-item.h")]
	public const string DESKTOP_ITEM_MINI_ICON;
	[CCode (cheader_filename = "libgnome/gnome-desktop-item.h")]
	public const string DESKTOP_ITEM_MOUNT_POINT;
	[CCode (cheader_filename = "libgnome/gnome-desktop-item.h")]
	public const string DESKTOP_ITEM_NAME;
	[CCode (cheader_filename = "libgnome/gnome-desktop-item.h")]
	public const string DESKTOP_ITEM_NO_DISPLAY;
	[CCode (cheader_filename = "libgnome/gnome-desktop-item.h")]
	public const string DESKTOP_ITEM_ONLY_SHOW_IN;
	[CCode (cheader_filename = "libgnome/gnome-desktop-item.h")]
	public const string DESKTOP_ITEM_PATH;
	[CCode (cheader_filename = "libgnome/gnome-desktop-item.h")]
	public const string DESKTOP_ITEM_PATTERNS;
	[CCode (cheader_filename = "libgnome/gnome-desktop-item.h")]
	public const string DESKTOP_ITEM_READ_ONLY;
	[CCode (cheader_filename = "libgnome/gnome-desktop-item.h")]
	public const string DESKTOP_ITEM_SORT_ORDER;
	[CCode (cheader_filename = "libgnome/gnome-desktop-item.h")]
	public const string DESKTOP_ITEM_SWALLOW_EXEC;
	[CCode (cheader_filename = "libgnome/gnome-desktop-item.h")]
	public const string DESKTOP_ITEM_SWALLOW_TITLE;
	[CCode (cheader_filename = "libgnome/gnome-desktop-item.h")]
	public const string DESKTOP_ITEM_TERMINAL;
	[CCode (cheader_filename = "libgnome/gnome-desktop-item.h")]
	public const string DESKTOP_ITEM_TERMINAL_OPTIONS;
	[CCode (cheader_filename = "libgnome/gnome-desktop-item.h")]
	public const string DESKTOP_ITEM_TRY_EXEC;
	[CCode (cheader_filename = "libgnome/gnome-desktop-item.h")]
	public const string DESKTOP_ITEM_TYPE;
	[CCode (cheader_filename = "libgnome/gnome-desktop-item.h")]
	public const string DESKTOP_ITEM_UNMOUNT_ICON;
	[CCode (cheader_filename = "libgnome/gnome-desktop-item.h")]
	public const string DESKTOP_ITEM_URL;
	[CCode (cheader_filename = "libgnome/gnome-desktop-item.h")]
	public const string DESKTOP_ITEM_VERSION;
}
