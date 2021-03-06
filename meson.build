project('gnome-games',
  ['vala', 'c'],
  version: '3.35.90',
  license: 'GPL3+',
  meson_version: '>= 0.46.1'
)

if get_option('profile') == 'development'
  profile = 'Devel'
  name_suffix = ' (Development)'
  vcs_tag = run_command('git', 'rev-parse', '--short', 'HEAD').stdout().strip()
  if vcs_tag == ''
    version_suffix = '-devel'
  else
    version_suffix = '-@0@'.format (vcs_tag)
  endif
else
  profile = ''
  name_suffix = ''
  version_suffix = ''
endif

application_id = 'org.gnome.Games@0@'.format(profile)

gnome = import ('gnome')
i18n = import('i18n')

cc = meson.get_compiler ('c')
valac = meson.get_compiler ('vala')

glib_min_version = '2.38'
manette_min_version = '0.2.0'
retro_gtk_min_version = '0.18.0'

archive_dep = dependency ('libarchive')
gio_dep = dependency ('gio-2.0', version: '>=' + glib_min_version)
glib_dep = dependency ('glib-2.0', version: '>=' + glib_min_version)
grilo_dep = dependency ('grilo-0.3')
gtk_dep = dependency ('gtk+-3.0')
handy_dep = dependency ('libhandy-1')
m_dep = cc.find_library('m', required : false)
manette_dep = dependency ('manette-0.2', version: '>=' + manette_min_version)
retro_gtk_dep = dependency ('retro-gtk-1', version: '>=' + retro_gtk_min_version)
rsvg_dep = dependency ('librsvg-2.0')
soup_dep = dependency ('libsoup-2.4')
sqlite_dep = dependency ('sqlite3')
tracker_sparql_dep = dependency ('tracker-sparql-2.0')
xml_dep = dependency ('libxml-2.0')

srcdir = join_paths (meson.source_root (), 'src')
podir = join_paths (meson.source_root (), 'po')

prefix = get_option('prefix')
bindir = join_paths (prefix, get_option ('bindir'))
datadir = join_paths (prefix, get_option ('datadir'))
libdir = join_paths (prefix, get_option ('libdir'))
libexecdir = join_paths (prefix, get_option ('libexecdir'))
localedir = join_paths (prefix, get_option ('localedir'))
servicedir = join_paths (datadir, 'dbus-1', 'services')
options_dir = join_paths (datadir, meson.project_name(), 'options')
plugins_dir = join_paths (libdir, meson.project_name(), 'plugins')

config_h = configuration_data ()
config_h.set_quoted ('APPLICATION_ID', application_id)
config_h.set_quoted ('GETTEXT_PACKAGE', meson.project_name ())
config_h.set_quoted ('GNOMELOCALEDIR', localedir)
config_h.set_quoted ('NAME_SUFFIX', name_suffix)
config_h.set_quoted ('OPTIONS_DIR', options_dir)
config_h.set_quoted ('PLUGINS_DIR', plugins_dir)
config_h.set_quoted ('PROFILE', profile)
config_h.set_quoted ('VERSION', '@0@@1@'.format (meson.project_version (), version_suffix))

configure_file (output: 'config.h', configuration: config_h)

config_dep = valac.find_library ('config', dirs: srcdir)

confinc = include_directories('.')
srcinc = include_directories('src')

add_project_arguments (
  '-DGETTEXT_PACKAGE="' + meson.project_name () + '"',
  '-DRETRO_GTK_USE_UNSTABLE_API',
  '-DHANDY_USE_UNSTABLE_API',
  language: 'c'
)

# FIXME Disable --disable-since-check after libhandy 1.0 is released
add_project_arguments (
  '--target-glib=' + glib_min_version,
  '--disable-since-check',
  language: 'vala'
)

meson.add_install_script (
  join_paths ('build-aux', 'post_install.py'),
  datadir
)

# FIXME 'plugins' have to be after 'src' as the plugins depend on the
# produced VAPI file and dependency tracking doesn't work as expected.
subdir ('data')
subdir ('po')
subdir ('src')
subdir ('plugins')
