state("Subnautica") {
    // 0 in menu, >0 in game
    bool notInMenu :  0x0142B8C8, 0x180, 0x40, 0xB8, 0xB8, 0x333;
    
    // Unity timer: reliable but still counting in menus
    float unityTimePassed : 0x0142B8C8, 0x180, 0x40, 0xB8, 0xB8, 0x2F4;

    // Paused
    bool isPaused : "fmodstudio.dll", 0x003047C0, 0x350, 0xF0, 0xC0, 0x678, 0xC4;

}
init {
    // https://raw.githubusercontent.com/Voxelse/ASLScripts/master/Livesplit.GRIS/Livesplit.GRIS.asl
	vars.ReadPointers = (Func<Process, IntPtr, int[], IntPtr>)((proc, basePtr, offsets) => {
		IntPtr rPtr = basePtr;
        var i = 0;
		foreach(int offset in offsets) {
			proc.ReadPointer((IntPtr)(rPtr.ToInt64()+offset), true, out rPtr);
		}
		return rPtr;
	});

    vars.initPointers = (Func<Dictionary<string, IntPtr>>)(() => {
        var signatures = new Dictionary<string, SigScanTarget> {
        {
                "rocket", new SigScanTarget(0x10, "00 00 00 00 55 48 8B EC 48 83 EC 10 48 8B 0C 25 ?? ?? ?? ?? 48")
            },
            {
                "dayNight", new SigScanTarget(0x8, "F3 0F 5A C0 48 8B 04 25 ?? ?? ?? ?? 48")
            },
            {
                "gameMode", new SigScanTarget(0x9, "56 48 83 EC 08 48 8B F1 BA ?? ?? ?? ?? 48 63 12")
            },
            {
                "player", new SigScanTarget(0x8, "36 03 00 00 4C 8B 2C 25 ?? ?? ?? ?? 49 8B CD 33 D2")
            }        
        };
        var pointers = new Dictionary<string, IntPtr>();
        var nbPointers = 0;
        foreach (var page in game.MemoryPages()) {
            var scanner = new SignatureScanner(game, page.BaseAddress, (int)page.RegionSize);
            foreach(var k in signatures.Keys) {
                if (!pointers.ContainsKey(k)) {
                    IntPtr ptr = scanner.Scan(signatures[k]);
                    if (ptr != IntPtr.Zero) {
                        pointers[k] = new IntPtr(game.ReadValue<int>(ptr));
                        nbPointers++;
                    }
                }
            }
            if (nbPointers == signatures.Count) {
                break;
            }
        }
        // Retry the same function if we don't have enough pointers, the aggressive way
        if (nbPointers < signatures.Count) {
            pointers = vars.initPointers();
        }
        return pointers;
    });

    vars.pointers = vars.initPointers();

}
startup {
    vars.runStarted = false;
    vars.previousTime = 0.0;
}
update {
    var dayNightPtr = vars.ReadPointers(game, vars.pointers["dayNight"], new int[] {0x0});
    vars.dayNight = game.ReadValue<double>((IntPtr)dayNightPtr+0x60);
    vars.gameMode = game.ReadValue<byte>((IntPtr)vars.pointers["gameMode"]);

    if(current.notInMenu) {
        var cinematicActivePtr = vars.ReadPointers(game, vars.pointers["player"], new int[] {0x0});
        vars.cinematicActive = game.ReadValue<int>((IntPtr)cinematicActivePtr+0x240);

        var cinematicStartedPtr = vars.ReadPointers(game, vars.pointers["player"], new int[] {0x0, 0x200});
        vars.cinematicStarted = game.ReadValue<int>((IntPtr)cinematicStartedPtr+0xF4);

        if(!vars.runStarted) {
            // Creative
            if(current.unityTimePassed > 0.0 && vars.gameMode == 0xFE) {
                vars.runStarted = true;
                vars.offsetTime = 0.0;
            }
            if(current.unityTimePassed > 0.0 && vars.gameMode != 0xFE && vars.cinematicActive == 0 && vars.cinematicStarted == 1) {
                vars.runStarted = true;
                vars.offsetTime = current.unityTimePassed + 480.0 -  Math.Max(480.0, vars.dayNight);
            }
        }
        else {
            var rktPtr = vars.ReadPointers(game, vars.pointers["rocket"], new int[] {0x0, 0x18, 0x20, 0x7D8, 0x10, 0x20});
            vars.rktRdy = game.ReadValue<float>((IntPtr)rktPtr+0x1B4);
        }

    }
    else {
        vars.runStarted = false;
    }
}
gameTime {
    if (vars.runStarted && vars.rktRdy == 0.0) {
        return TimeSpan.FromSeconds(current.unityTimePassed-vars.offsetTime);
    }
}
isLoading {
    return current.isPaused;
}
start {
    if (vars.runStarted) return true;
}
split {
    if (vars.runStarted) {
        if (vars.rktRdy > 0.0) {
            vars.runStarted = false;
            return true;
        }
    }
}
reset {
    if (!current.notInMenu) return true;
}