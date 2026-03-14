# Shadow Settings

**The settings hiding in the shadow of your system**

Shadow Settings dynamically discovers and surfaces hidden GNOME desktop settings
that are not exposed in the standard Settings app. It scans your system at runtime
to find settings specific to your GNOME version and installed components.

## Features

- Discovers hundreds of hidden GSettings keys automatically
- Organizes settings into logical categories (Desktop, Appearance, Windows, Input, Privacy, Power)
- Search across all discovered settings with Ctrl+F
- Reset any setting to its default value
- Three distinctive Art Deco visual themes (Gotham Night, Gotham Day, Wayne Manor)
- Lid-close action controls (native build only, requires logind)

## Install

### Flatpak (recommended)

```bash
flatpak install flathub io.github.matrixshader.ShadowSettings
```

### Build from Source

**Dependencies**

Fedora:
```bash
sudo dnf install vala meson gtk4-devel libadwaita-devel
```

Ubuntu/Debian:
```bash
sudo apt install valac meson libgtk-4-dev libadwaita-1-dev
```

**Build and run**

```bash
meson setup builddir
meson compile -C builddir
./builddir/shadow-settings
```

**System-wide install**

```bash
meson setup builddir --prefix=/usr
meson compile -C builddir
sudo meson install -C builddir
```

## License

GPL-3.0-or-later

## Credits

Made by [Matrix Shader](https://matrixshader.com)
