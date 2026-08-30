final: prev: {
  kdePackages = prev.kdePackages // {
      plasma-bigscreen = prev.kdePackages.plasma-bigscreen.overrideAttrs (old: {
          buildInputs = (old.buildInputs or [ ]) ++ [ prev.kdePackages.kdeconnect-kde ];
          preFixup = ''
            wrapQtApp $out/bin/plasma-bigscreen-wayland \
              --prefix QML2_IMPORT_PATH : "${prev.kdePackages.kdeconnect-kde}/lib/qt-6/qml"
          '';
      });
  };
}
