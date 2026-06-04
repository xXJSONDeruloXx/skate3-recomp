Skate 3 Recomp Linux Setup

This package does not include Skate 3 game files.

Quick start:

1. Open the folder named "Skate 3 Files".
2. Put your Skate 3 dump in that folder.
3. Run "Launch Skate 3 Recomp.sh".

Optional desktop launcher:

- Double-click "Launch Skate 3 Recomp.desktop"
- On some Linux desktops you may need to mark it trusted / allow launching.

The launcher looks for:

- default.xex
- default.xex_uncrypted.xex
- data
- nxeart

It stores local runtime state in:

- user-data
- cache

Decrypting default.xex with XexTool:

Use this only with your own legally obtained Skate 3 dump. Keep the original
 default.xex in place and create a separate decrypted copy:

  xextool -e d -c b -o default.xex_uncrypted.xex default.xex
