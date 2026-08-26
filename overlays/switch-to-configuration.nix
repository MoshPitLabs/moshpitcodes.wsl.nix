_final: prev: {
  switch-to-configuration-ng = prev.switch-to-configuration-ng.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      substituteInPlace src/main.rs \
        --replace-fail \
          '.env("XDG_RUNTIME_DIR", runtime_path)' \
          '.env("DBUS_SESSION_BUS_ADDRESS", format!("unix:path={}/bus", runtime_path.display()))
                    .env("XDG_RUNTIME_DIR", runtime_path)'
    '';
  });
}
