project('shadow-settings', 'vala', 'c',
  version: '1.0.0',
  meson_version: '>= 0.62.0',
)

gnome = import('gnome')

deps = [
  dependency('gtk4', version: '>= 4.12'),
  dependency('libadwaita-1', version: '>= 1.4'),
  dependency('gio-2.0'),
  dependency('glib-2.0'),
]

# Compile CSS stylesheets into GResource binary
gresource = gnome.compile_resources(
  'shadow-settings-resources',
  'data/io.github.matrixshader.ShadowSettings.gresource.xml',
  source_dir: 'data',
)

# Compile GSettings schema for dev builds (sets GSETTINGS_SCHEMA_DIR)
gnome.compile_schemas(
  depend_files: 'data/io.github.matrixshader.ShadowSettings.gschema.xml',
)

sources = files(
  'src/main.vala',
  'src/application.vala',
  'src/window.vala',
  'src/core/setting-def.vala',
  'src/core/schema-scanner.vala',
  'src/core/category-mapper.vala',
  'src/core/widget-factory.vala',
  'src/core/theme-manager.vala',
  'src/core/animator.vala',
  'src/registry/desktop.vala',
  'src/registry/appearance.vala',
  'src/registry/windows.vala',
  'src/registry/input.vala',
  'src/registry/power.vala',
  'src/registry/privacy.vala',
  'src/panels/power.vala',
  'src/helpers/logind-helper.vala',
  'src/helpers/safe-settings.vala',
)

executable('shadow-settings',
  sources, gresource,
  dependencies: deps,
  install: true,
)

install_data(
  'data/io.github.matrixshader.ShadowSettings.desktop',
  install_dir: get_option('datadir') / 'applications',
)

install_data(
  'data/icons/hicolor/scalable/apps/io.github.matrixshader.ShadowSettings.svg',
  install_dir: get_option('datadir') / 'icons/hicolor/scalable/apps',
)

install_data(
  'data/icons/hicolor/scalable/apps/io.github.matrixshader.ShadowSettings-symbolic.svg',
  install_dir: get_option('datadir') / 'icons/hicolor/scalable/apps',
)

install_data(
  'polkit/io.github.matrixshader.ShadowSettings.policy',
  install_dir: get_option('datadir') / 'polkit-1/actions',
)

install_data(
  'data/io.github.matrixshader.ShadowSettings.gschema.xml',
  install_dir: get_option('datadir') / 'glib-2.0' / 'schemas',
)

gnome.post_install(glib_compile_schemas: true)
