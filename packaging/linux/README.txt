Skate 3 Recomp Linux Setup

This package does not include Skate 3 game files.

Quick start:

1. Open the folder named "Skate 3 Files".
2. Put your Skate 3 dump in that folder.
3. Run "Setup Skate 3 Recomp.sh".
4. When setup finishes, launch with "Launch Skate 3 Recomp.sh".

Optional desktop launchers:

- Double-click "Setup Skate 3 Recomp.desktop"
- Double-click "Launch Skate 3 Recomp.desktop"
- On some Linux desktops you may need to mark them trusted / allow launching.

The setup tool looks for:

- default.xex
- default.xex_uncrypted.xex
- data
- nxeart

The setup flow keeps your original dump untouched. It creates:

- work/assets
- work/runtime-assets
- work/user-data
- work/cache

After setup, the launcher starts the game from work/runtime-assets and uses the
same default launch preset as the Windows package.

Decrypting default.xex with XexTool:

Use this only with your own legally obtained Skate 3 dump. Keep the original
default.xex in place and create a separate decrypted copy:

  xextool -e d -c b -o default.xex_uncrypted.xex default.xex
