//
//  main.swift
//  Helium
//
//  Created by Fuuko on 2024/3/24.
//

import SwiftUI

private var cachesDirectoryPath: String?
private var hudPIDFilePath: String?

let argc = CommandLine.argc
let argv = CommandLine.unsafeArgv
let args = CommandLine.arguments

if argc <= 1 {
    UIApplicationMain(argc, argv, nil, NSStringFromClass(AppDelegate.self))
} else if args[1] == "-hud" {
    runMainHUDBridger()
} else if args[1] == "-exit" {
    let pidFilePath = getPIDFilePath()
    if let pidString = try? String(contentsOfFile: pidFilePath, encoding: .utf8) {
        if let pid = pidString.trimmingCharacters(in: .whitespacesAndNewlines).pid_tValue {
            kill(pid, SIGKILL)
            unlink(pidFilePath)
        }
    }
    exit(EXIT_SUCCESS)
} else if args[1] == "-check" {
    if let pidString = try? String(contentsOfFile: getPIDFilePath(), encoding: .utf8) {
        if let pid = pidString.trimmingCharacters(in: .whitespacesAndNewlines).pid_tValue {
            let killed = kill(pid, 0)
            exit(killed == 0 ? EXIT_FAILURE : EXIT_SUCCESS)
        } else {
            exit(EXIT_SUCCESS) // No valid PID found, HUD is not running
        }
    } else {
        exit(EXIT_SUCCESS) // No PID file found, HUD is not running
    }
}

private func getPIDFilePath() -> String {
    DispatchQueue.once(token: "hudPIDFilePath") {
        if let cachesDirectory = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first {
            cachesDirectoryPath = cachesDirectory
            hudPIDFilePath = (cachesDirectoryPath! as NSString).appendingPathComponent("hud.pid")
        }
    }
    return hudPIDFilePath ?? ""
}

extension String {
    var pid_tValue: pid_t? {
        return pid_t(self)
    }
}
