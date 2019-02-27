state("Subnautica") {
    // 0 in menu, >0 in game
    bool notInMenu :  0x0142B8C8, 0x180, 0x40, 0xB8, 0xB8, 0x333;

    // When starting rocket
    bool launchRocket : 0x0142B900, 0x30, 0xF8, 0x8, 0x230, 0x3C0, 0x18, 0x20, 0x7D8, 0x10, 0x20, 0x1B4;

    // Time passed
    double timePassed : 0x0142B5E8, 0x50, 0x2E0, 0x98, 0x1D0, 0x60;
    float unityTimePassed : 0x0142B8C8, 0x180, 0x40, 0xB8, 0xB8, 0x2F4;

    // Paused
    bool isPaused : "fmodstudio.dll", 0x003047C0, 0x350, 0xF0, 0xC0, 0x678, 0xC4;
}

startup {
    vars.runStarted = false;
    vars.previousTimePassed = 1000.0;
}
update {
    if(current.notInMenu) {
        if(!vars.runStarted) {
            if(current.timePassed > 480.02) {
                vars.runStarted = true;
            }
            vars.offsetTime = current.unityTimePassed + 480.0 -  Math.Max(480.0, current.timePassed);
        }

    }
    else {
        vars.runStarted = false;
    }
}
gameTime {
    if (vars.runStarted) {
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
        if (current.launchRocket) {
            return true;
            vars.runStarted = false;
        }
    }
}
reset {
    if (!current.notInMenu) return true;
}