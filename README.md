# xholdkey
Xholdkey is a program, that works in an x11 session on a posix os like Linux, that every 50 milliseconds (by default) queries the keyboard to check if a key is pressed or released and if so executes a user specified command.
# Usage
xholdkey `[-p <polling rate>]` `<X11 KeySym[s]>` `<program: in keypress>` `[program: in keyrelease]`

### `-p <polling rate>` (optional)
Set the polling rate in milliseconds.  
Default: 50

### `<X11 KeySym[s]>`
One or more X11 keysyms to listen for.  
- Without the `XK_` prefix (e.g., use `Super_L` for the left Windows key).  
- For a full list of keysyms, see `/usr/include/X11/keysymdef.h` or use the `xev` utility (arch linux package: `xorg-xev`).  
- To specify multiple keysyms, separate them with commas (e.g., `Super_L,Super_R`).

### `<program: in keypress>`
The command to execute when any of the specified keys is pressed.  
- Commands run via `sh`, so you can chain multiple commands with `;`, but remember to wrap the argument in quotes for that to work.
- The shell receives two positional parameters:
  - `$1`: the keysym that triggered the event (e.g., `Super_L`).  
  - `$2`: an integer flag: `1` if the key was pressed, `0` otherwise (for release events).

### `[program: in keyrelease]` (optional)
The command to execute when any of the specified keys is released.  
- Acts the same as the argument before, but can be `_` to copy the keypress program for the release action.

# Build and install
To build you must have an odin compiler (dev-2026-06 was used in the project).
First, clone the project somewhere with:
``` bash
git clone https://github.com/Buldogghi/xholdkey
```
Then cd into the project's root directory and execute:
``` bash
odin build .
```
A file called `xholdkey` will be created, to run it type
``` bash
./xholdkey
```
If you want to have it in yout environment you can manually move or copy it to ~/.local/bin:
``` bash
mkdir -p ~/.local/bin # Make sure that the directory exists
mv xholdkey ~/.local/bin
```
Now in any shell you can type `xholdkey` to use it.
