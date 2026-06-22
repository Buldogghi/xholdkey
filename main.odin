package main

import "base:runtime"
import "core:fmt"
import "core:os"
import "core:os/old"
import "core:strconv"
import "core:strings"
import "core:sys/posix"
import "core:time"
import "vendor:x11/xlib"

polling_rate: uint = 50
keysym_str, keypress, keyrelease: string

usage :: proc() {
	usage := `: [-p <polling rate>] <X11 KeySym[s]> <program: in keypress> [program: in keyrelease]
	(optional) '-p <polling rate>' is a flag to set the polling rate in milliseconds, defaults to 50
  'KeySym[s]' is the keysym withouth the "XK_" prefix (like "Super_L" for the left 'windows' key, refer to /usr/include/X11/keysymdef.h or the xev (xorg-xev) program), to check for multiple separate them with a ','
  'program: in keypress' is the name of the program to execute when any of the keysym[s] is pressed, it will execute in sh so to run multiple commands separate them with ';' (remember to wrap the argument in "" or ''), also keep in mind that the key will be passed as argument to the shell as $1 and $2 will be an int that is 1 if the key has been pressed, otherwise 0
  (optional) 'program: in keyrelease' is the same as keypress but when the key is released, set to '_' to copy keypress or leave blank to not execute anything
`
	fmt.print(os.args[0], usage, sep = "")
	os.exit(1)
}

press :: proc(key: string) {
	execute(keypress, key, true)
}

release :: proc(key: string) {
	execute(keyrelease, key, false)
}

execute :: proc(program: string, arg: string, pressed: bool) -> i32 {
	shell :: "sh"
	wstatus: i32
	args: []string = {"-c", program, shell, arg, pressed ? "1" : "0"}
	pid := posix.fork()
	if pid == 0 {
		old.execvp(shell, args[:])
		return -1
	} else if pid == -1 {
		return -1
	} else {
		posix.wait(&wstatus)
		return posix.WEXITSTATUS(wstatus)
	}
}

main :: proc() {
	execute_on_key_release := true
	{ 	// Parse arguments
		if len(os.args) < 3 do usage()
		argc := len(os.args)
		idx := 0
		args: [3]string = ""
		for i := 1; i < argc; i += 1 {
			arg := os.args[i]
			if arg[0] == '-' {
				switch arg {
				case "-p":
					if i + 1 >=
					   argc {fmt.eprintfln("Insert polling rate after '%s'", arg); os.exit(1)}
					next := os.args[i + 1]
					num, ok := strconv.parse_uint(next)
					if !ok {fmt.eprintfln("'%s' isn't a valid number (must be a positive integer)", next); os.exit(1)}
					if num == 0 {fmt.eprintfln("The polling rate can't be 0"); os.exit(1)}
					polling_rate = num
					i += 1
					continue
				case:
					fmt.eprintfln("Invalid flag '%s'", arg)
					os.exit(1)
				}
			}
			if idx >= len(args) {fmt.printfln("Invalid argument '%s'", arg); os.exit(1)}
			args[idx] = arg
			idx += 1
		}
		if idx > len(args) do usage()
		keysym_str = args[0]
		keypress = args[1]
		switch args[2] {
		case "_":
			keyrelease = keypress
		case "":
			execute_on_key_release = false
		case:
			keyrelease = args[2]
		}
	}

	display := xlib.OpenDisplay(nil)
	if display == nil {
		fmt.eprintln("Error opening display (are you using X11?)")
		os.exit(1)
	}
	root := xlib.DefaultRootWindow(display)

	keys := make([^]u32, 8)
	keysyms_str := strings.split(keysym_str, ",")
	keysyms := make([]xlib.KeySym, len(keysyms_str))
	for keysym_str, i in keysyms_str {
		runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
		keysyms[i] = xlib.StringToKeysym(
			strings.clone_to_cstring(keysym_str, context.temp_allocator),
		)
		if int(keysyms[i]) ==
		   xlib.NoSymbol {fmt.eprintfln("Invalid keysym: '%s'", keysym_str); os.exit(1)}
	}
	pressed := make([]bool, len(keysyms_str))
	for {
		xlib.QueryKeymap(display, keys)
		for keysym, i in keysyms {
			keycode := xlib.KeysymToKeycode(display, keysym)
			if keys[keycode / 32] & (1 << (keycode % 8)) != 0 {
				if !pressed[i] { 	// Key is pressed
					pressed[i] = true
					press(keysyms_str[i])
				}
			} else {
				if pressed[i] { 	// Key is released
					pressed[i] = false
					if execute_on_key_release do release(keysyms_str[i])
				}
			}
		}
		time.sleep(time.Duration(polling_rate) * time.Millisecond)
	}
}
