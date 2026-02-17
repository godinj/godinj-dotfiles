# Audio development environment — PKG_CONFIG_PATH and aliases
# Source this from .zshrc to enable audio dev tooling (Ardour, JUCE, etc.)

# Use pkg-config to resolve paths dynamically (version-independent)
for lib in glib-2.0 glibmm-2.4 libarchive liblo taglib vamp-hostsdk fftw3 pango gobject-introspection-1.0; do
  pkg_path="$(pkg-config --variable=pcfiledir "$lib" 2>/dev/null)"
  if [ -n "$pkg_path" ]; then
    export PKG_CONFIG_PATH="$PKG_CONFIG_PATH:$pkg_path"
  fi
done

# MacPorts fallback
[ -d /opt/local/lib/pkgconfig ] && export PKG_CONFIG_PATH="$PKG_CONFIG_PATH:/opt/local/lib/pkgconfig"

# Ardour aliases
alias ardour='cd $HOME/dev/ardour_dev/ardour && ./install/bin/ardour9'
