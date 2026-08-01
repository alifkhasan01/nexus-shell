import Quickshell
import "./modules" as Modules

ShellRoot {
    // Satu Bar per monitor
    Variants {
        model: Quickshell.screens

        Modules.Bar {
            required property var modelData
            screen: modelData
        }
    }
}
