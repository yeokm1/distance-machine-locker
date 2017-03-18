//
//  UtilityFunctions.swift
//  Distance Mac Locker
//
//  Created by Yeo Kheng Meng on 7/1/17.
//  Copyright © 2017 Yeo Kheng Meng. All rights reserved.
//

import Foundation
import IOKit
import IOKit.serial

let PATH_PREFIX_ARDUINO = "/dev/cu.usbmodem"


//Referenced from:
//https://www.mac-usb-serial.com/wordpress/detect-serial-devices-mac-os-x-using-swift/
//http://stackoverflow.com/questions/25320213/searching-serial-ports-with-iokit-swift
func getPossibleArduinoPorts() -> [String]{
    
    var result: [String] = []
    
    let masterPort: mach_port_t = kIOMasterPortDefault

    let classesToMatch: CFDictionary = IOServiceMatching(kIOSerialBSDServiceValue)
    // the iterator that will contain the results of IOServiceGetMatchingServices
    var matchingServices: io_iterator_t = 0
    
    let kernResult = IOServiceGetMatchingServices(masterPort, classesToMatch, &matchingServices)
    if kernResult == KERN_SUCCESS {
        
        var serialService: io_object_t
        repeat {
            serialService = IOIteratorNext(matchingServices)
            
            let path = getPortNameFromDevice(serialService)
            
            if path.hasPrefix(PATH_PREFIX_ARDUINO){
                result.append(path)
            }
            
        } while serialService != 0;
        
        // success
    } else {
        // error
    }
    
    return result
}

func getPortNameFromDevice(_ device: io_object_t) -> String{
    
    if (device != 0) {
        let key: CFString! = "IOCalloutDevice" as CFString!
        let bsdPathAsCFtring: AnyObject? = IORegistryEntryCreateCFProperty(device, key, kCFAllocatorDefault, 0).takeUnretainedValue()
        let bsdPath = bsdPathAsCFtring as! String?
        
        if let path = bsdPath {
            return path
        } else {
            return ""
        }
    } else {
        return ""
    }
    
}


func runCommand(cmd : String, args : [String]) -> (output: [String], error: [String], exitCode: Int32) {
    
    var output : [String] = []
    var error : [String] = []
    
    let task = Process()
    task.launchPath = cmd
    
    if !args.isEmpty{
        task.arguments = args
    }
    
    let outpipe = Pipe()
    task.standardOutput = outpipe
    let errpipe = Pipe()
    task.standardError = errpipe
    
    task.launch()
    
    let outdata = outpipe.fileHandleForReading.readDataToEndOfFile()
    if var string = String(data: outdata, encoding: .utf8) {
        string = string.trimmingCharacters(in: .newlines)
        output = string.components(separatedBy: "\n")
    }
    
    let errdata = errpipe.fileHandleForReading.readDataToEndOfFile()
    if var string = String(data: errdata, encoding: .utf8) {
        string = string.trimmingCharacters(in: .newlines)
        error = string.components(separatedBy: "\n")
    }
    
    task.waitUntilExit()
    let status = task.terminationStatus
    
    return (output, error, status)
}
