project(
  'synapse-switchboard-plugin',
  'vala',
  'c',
  license: 'GPL-3.0',
  meson_version: '>=0.50.0',
  version: '0.1.0'
)

vala = meson.get_compiler('vala')

vapi_dir = join_paths(meson.source_root(), 'vapi')

prefix = get_option('prefix')
lib_dir = join_paths(prefix, get_option('libdir'))
data_dir = join_paths(prefix, get_option('datadir'))
pkglib_dir = join_paths(lib_dir, 'synapse')

gee_version = '>=0.5.2'
glib_version = '>=2.40.0'
gtk_version = '>=3.0.0'

gdk_dep = dependency('gdk-x11-3.0', version: gtk_version)
gee_dep = dependency('gee-0.8', version: gee_version)
gio_dep = dependency('gio-2.0', version: glib_version)
glib_dep = dependency('glib-2.0', version: glib_version)
gtk_dep = dependency('gtk+-3.0', version: gtk_version)
synapse_dep = dependency('synapse-1.0')
posix_dep = vala.find_library('posix')

plugins_dir = synapse_dep.get_pkgconfig_variable(
  'pluginsdir', define_variable: ['libdir', lib_dir])

# configuration file
conf = configuration_data()
conf.set_quoted('PLUGINS_DIR', join_paths(prefix,
  get_option('libdir'), 'io.elementary.wingpanel.applications-menu'))

# write configuration to config.h
config_h = configure_file(
  output: 'config.h',
  configuration: conf
)

config_dep = declare_dependency(
  dependencies: vala.find_library('config', dirs: vapi_dir),
  sources: config_h
)

add_project_arguments([
    '-DG_LOG_DOMAIN="@0@"'.format(meson.project_name())
  ],
  language:'c'
)

shared_library(
  'switchboardplugin',
  files(
    'src/Main.vala',
    'src/WorkerLink.vala'
  ),
  dependencies: [
    gdk_dep,
    gee_dep,
    gio_dep,
    glib_dep,
    gtk_dep,
    posix_dep,
    synapse_dep,
    config_dep
  ],
  install: true,
  install_dir: plugins_dir
)
