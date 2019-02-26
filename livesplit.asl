state("Subnautica") {
    // 0 in menu, >0 in game
    bool notInMenu :  0x0142B8C8, 0x180, 0x40, 0xB8, 0xB8, 0x333;

    // 1 during cinematic
    bool cinematicModeActive : 0x0142B908, 0x190, 0x150, 0xD0, 0x18, 0x240;

    // 1 when cinematic has started
    bool startedIntroCinematic : 0x0142B908, 0x190, 0x150, 0xD0, 0x18, 0x200, 0xF4;

    // When starting the game : 0 in creative, 1 in survival/hardcore
    bool usedToolsGeneration : 0x0142B908, 0x190, 0x150, 0xD0, 0x18, 0x198, 0x48;

    // When starting rocket
    bool launchRocket : 0x0142B900, 0x30, 0xF8, 0x8, 0x230, 0x3C0, 0x18, 0x20, 0x7D8, 0x10, 0x20, 0x1B4;
}

startup {
    vars.runStarted = false;
}
update {
    if(current.notInMenu) {
        // Survival / Hardcore
        if(!current.cinematicModeActive && current.startedIntroCinematic && !current.usedToolsGeneration) {
            vars.runStarted = true;
        }
        // Creative
        if(!current.startedIntroCinematic && !current.cinematicModeActive && current.usedToolsGeneration) {
            vars.runStarted = true;
        }
    }
    else {
        vars.runStarted = false;
    }
}
start {
    if (vars.runStarted) return true;
}
split {
    if (vars.runStarted) {
        if (current.launchRocket) {
            return true;
        }
    }
}
reset {
    if (!current.notInMenu) return true;
}