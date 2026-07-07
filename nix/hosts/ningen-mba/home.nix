{ pkgs, lib, ... }:
{
  home.file."Applications/Org Protocol.app/Contents/Info.plist".text = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
      "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>CFBundleDisplayName</key>
      <string>Org Protocol</string>
      <key>CFBundleExecutable</key>
      <string>org-protocol-client</string>
      <key>CFBundleIdentifier</key>
      <string>org.ningen.org-protocol</string>
      <key>CFBundleName</key>
      <string>Org Protocol</string>
      <key>CFBundlePackageType</key>
      <string>APPL</string>
      <key>CFBundleURLTypes</key>
      <array>
        <dict>
          <key>CFBundleURLName</key>
          <string>Org Protocol</string>
          <key>CFBundleURLSchemes</key>
          <array>
            <string>org-protocol</string>
          </array>
        </dict>
      </array>
      <key>LSUIElement</key>
      <true/>
    </dict>
    </plist>
  '';

  home.file."Applications/Org Protocol.app/Contents/MacOS/org-protocol-client" = {
    executable = true;
    text = ''
      #!${pkgs.runtimeShell}
      exec ${pkgs.emacs}/bin/emacsclient -n -a "" "$@"
    '';
  };

  home.activation.registerOrgProtocol = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    app="$HOME/Applications/Org Protocol.app"
    lsregister="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"

    if [ -x "$lsregister" ] && [ -d "$app" ]; then
      "$lsregister" -f "$app"
    fi
  '';
}
