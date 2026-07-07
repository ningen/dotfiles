{ pkgs, lib, ... }:
{
  home.file."Library/Scripts/org-protocol-client.applescript".text = ''
    on open location thisUrl
      do shell script "${pkgs.emacs}/bin/emacsclient -n --alternate-editor=false " & quoted form of thisUrl
    end open location
  '';

  home.activation.registerOrgProtocol = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    script="$HOME/Library/Scripts/org-protocol-client.applescript"
    app="$HOME/Applications/Org Protocol.app"
    osacompile="/usr/bin/osacompile"
    plistbuddy="/usr/libexec/PlistBuddy"
    lsregister="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"

    if [ -x "$osacompile" ] && [ -f "$script" ]; then
      rm -rf "$app"
      "$osacompile" -o "$app" "$script"
    fi

    if [ -x "$plistbuddy" ] && [ -f "$app/Contents/Info.plist" ]; then
      "$plistbuddy" -c "Set :CFBundleDisplayName Org Protocol" "$app/Contents/Info.plist" 2>/dev/null || \
        "$plistbuddy" -c "Add :CFBundleDisplayName string Org Protocol" "$app/Contents/Info.plist"
      "$plistbuddy" -c "Set :CFBundleIdentifier org.ningen.org-protocol" "$app/Contents/Info.plist" 2>/dev/null || \
        "$plistbuddy" -c "Add :CFBundleIdentifier string org.ningen.org-protocol" "$app/Contents/Info.plist"
      "$plistbuddy" -c "Set :CFBundleName Org Protocol" "$app/Contents/Info.plist" 2>/dev/null || \
        "$plistbuddy" -c "Add :CFBundleName string Org Protocol" "$app/Contents/Info.plist"
      "$plistbuddy" -c "Set :LSUIElement true" "$app/Contents/Info.plist" 2>/dev/null || \
        "$plistbuddy" -c "Add :LSUIElement bool true" "$app/Contents/Info.plist"
      "$plistbuddy" -c "Delete :CFBundleURLTypes" "$app/Contents/Info.plist" 2>/dev/null || true
      "$plistbuddy" -c "Add :CFBundleURLTypes array" "$app/Contents/Info.plist"
      "$plistbuddy" -c "Add :CFBundleURLTypes:0 dict" "$app/Contents/Info.plist"
      "$plistbuddy" -c "Add :CFBundleURLTypes:0:CFBundleURLName string Org Protocol" "$app/Contents/Info.plist"
      "$plistbuddy" -c "Add :CFBundleURLTypes:0:CFBundleURLSchemes array" "$app/Contents/Info.plist"
      "$plistbuddy" -c "Add :CFBundleURLTypes:0:CFBundleURLSchemes:0 string org-protocol" "$app/Contents/Info.plist"
    fi

    if [ -x "$lsregister" ] && [ -d "$app" ]; then
      "$lsregister" -f "$app"
    fi
  '';
}
