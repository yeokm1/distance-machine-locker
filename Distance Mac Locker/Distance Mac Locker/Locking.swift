//
//  Locking.swift
//  Distance Mac Locker
//
//  Created by Yeo Kheng Meng on 7/1/17.
//  Copyright © 2017 Yeo Kheng Meng. All rights reserved.
//

import Cocoa
import AppKit

class Locking: NSObject {
    
    let DEFAULT_LOCK_DISTANCE = 60

    let KEY_STORE_DISTANCE = "lockingDistance"
    
    let MINIMUM_LOCK_WINDOW = 5.0 //seconds

    var timeLockEngaged : Date = Date()
    
    var isSystemLocked: Bool = false
    
    let notiCentre = DistributedNotificationCenter.default()
    
    
    public override init(){
        super.init()
        
        notiCentre.addObserver(self, selector: #selector(screenIsLocked), name: NSNotification.Name(rawValue: "com.apple.screenIsLocked"), object: nil)
        notiCentre.addObserver(self, selector: #selector(screenIsUnlocked), name: NSNotification.Name(rawValue: "com.apple.screenIsUnlocked"), object: nil)

    }
    
    
    
    func screenIsLocked(){
        isSystemLocked = true
        print("System Locked " + String(Date.timeIntervalSinceReferenceDate))
    }
    
    func screenIsUnlocked(){
        isSystemLocked = false
        print("System Unlocked " + String(Date.timeIntervalSinceReferenceDate))
    }
    
    
    func getLockingDistance() -> Int{
        let defaults = UserDefaults.standard
        var storedValue: Int = defaults.integer(forKey: KEY_STORE_DISTANCE)
        
        if storedValue == 0{
            setLockingDistance(newDistance: DEFAULT_LOCK_DISTANCE)
            storedValue = DEFAULT_LOCK_DISTANCE
        }
        
        return storedValue
    }
    
    func setLockingDistance(newDistance: Int){
        let defaults = UserDefaults.standard
        defaults.set(newDistance, forKey: KEY_STORE_DISTANCE)
        
    }
    
    
    
    func lockMachine(){
        
        let elapsed: TimeInterval = Date().timeIntervalSince(timeLockEngaged)
        
        if !isSystemLocked && elapsed > MINIMUM_LOCK_WINDOW{
            actualLockCall()
            timeLockEngaged = Date()
        }
    }
    
    //Reference http://stackoverflow.com/questions/1976520/lock-screen-by-api-in-mac-os-x
    func actualLockCall(){
        print("Lock Call")
        
        //Run command: /System/Library/CoreServices/Menu Extras/User.menu/Contents/Resources/CGSession -suspend
        let lockCommand = "/System/Library/CoreServices/Menu Extras/User.menu/Contents/Resources/CGSession"
        let lockArgument = ["-suspend"]
        
        _ = runCommand(cmd: lockCommand, args: lockArgument)
        
    }


}
