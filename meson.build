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

sources = files(
  'src/main.vala',
  'src/application.vala',
  'src/window.vala',
  'src/core/setting-def.vala',
  'src/core/schema-scanner.vala',
  'src/core/category-mapper.vala',
  'src/panels/power.vala',
  'src/panels/windows.vala',
  'src/panels/desktop.vala',
  'src/panels/appearance.vala',
  'src/panels/input.vala',
  'src/helpers/logind-helper.vala',
  'src/helpers/safe-settings.vala',
)

executable('shadow-settings',
  sources,
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
  'polkit/io.github.matrixshader.ShadowSettings.policy',
  install_dir: get_option('datadir') / 'polkit-1/actions',
)
