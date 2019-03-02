state("Subnautica") {
    // 0 in menu, >0 in game
    bool notInMenu :  0x0142B8C8, 0x180, 0x40, 0xB8, 0xB8, 0x333;
    
    // Unity timer: reliable but still counting in menus
    float unityTimePassed : 0x0142B8C8, 0x180, 0x40, 0xB8, 0xB8, 0x2F4;

    // Paused
    bool isPaused : "fmodstudio.dll", 0x003047C0, 0x350, 0xF0, 0xC0, 0x678, 0xC4;

    // cinematicModeActive
    byte cinematicModeActive : 0x0142B908, 0x190, 0x150, 0xD0, 0x18, 0x200, 0x28, 0x86;

    // startedIntroCinematic
    byte startedIntroCinematic : 0x0142B908, 0x190, 0x150, 0xD0, 0x18, 0x200, 0xF4;

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

    vars.baseDayNightPtr = new IntPtr();
    vars.baseRktPtr = new IntPtr();
    vars.baseGameModePtr = new IntPtr();

    foreach (var page in game.MemoryPages()) {
        var scanner = new SignatureScanner(game, page.BaseAddress, (int)page.RegionSize);

        IntPtr ptr = scanner.Scan(new SigScanTarget(0x10, "00 00 00 00 55 48 8B EC 48 83 EC 10 48 8B 0C 25 ?? ?? ?? ?? 48"));
        if (ptr != IntPtr.Zero) {
            vars.baseRktPtr = new IntPtr(game.ReadValue<int>(ptr));
            break;
        }
    }

    foreach (var page in game.MemoryPages()) {
        var scanner = new SignatureScanner(game, page.BaseAddress, (int)page.RegionSize);

        IntPtr ptr = scanner.Scan(new SigScanTarget(0x8, "F3 0F 5A C0 48 8B 04 25 ?? ?? ?? ?? 48"));
        if (ptr != IntPtr.Zero) {
            vars.baseDayNightPtr = new IntPtr(game.ReadValue<int>(ptr));
            break;
        }
    }

    foreach (var page in game.MemoryPages()) {
        var scanner = new SignatureScanner(game, page.BaseAddress, (int)page.RegionSize);

        IntPtr ptr = scanner.Scan(new SigScanTarget(0x9, "56 48 83 EC 08 48 8B F1 BA ?? ?? ?? ?? 48 63 12"));
        if (ptr != IntPtr.Zero) {
            vars.baseGameModePtr = new IntPtr(game.ReadValue<int>(ptr));
            break;
        }
    }
}
startup {
    vars.runStarted = false;
    vars.rktRdy = 0.0;
    vars.previousTime = 0.0;
}
update {
    var dayNightPtr = vars.ReadPointers(game, vars.baseDayNightPtr, new int[] {0x0});
    vars.dayNight = game.ReadValue<double>((IntPtr)dayNightPtr+0x60);
    vars.gameMode = game.ReadValue<byte>((IntPtr)vars.baseGameModePtr);

    if(current.notInMenu) {
        if(!vars.runStarted) {
            // Creative
            if(current.unityTimePassed > 0.0 && vars.gameMode == 0xFE) {
                vars.runStarted = true;
                vars.offsetTime = 0.0;
            }
            if(current.unityTimePassed > 0.0 && vars.gameMode != 0xFE && current.cinematicModeActive == 0 && current.startedIntroCinematic == 1) {
                vars.runStarted = true;
                vars.offsetTime = current.unityTimePassed + 480.0 -  Math.Max(480.0, vars.dayNight);
            }
        }
        else {
            var rktPtr = vars.ReadPointers(game, vars.baseRktPtr, new int[] {0x0, 0x18, 0x20, 0x7D8, 0x10, 0x20});
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