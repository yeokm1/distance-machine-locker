//
//  USBWatcher.swift
//  Distance Mac Locker
//
//  Modified from from http://stackoverflow.com/a/41279799
//
//  Created by Yeo Kheng Meng on 18/3/17.
//  Copyright © 2017 Yeo Kheng Meng. All rights reserved.
//

import Foundation
import IOKit
import IOKit.usb
import IOKit.serial


public protocol USBWatcherDelegate: class {
    /// Called on the main thread when a device is disconnected.
    func deviceRemoved(_ device: io_object_t)
}

/// An object which observes USB devices added and removed from the system.
/// Abstracts away most of the ugliness of IOKit APIs.
public class USBWatcher {
    private weak var delegate: USBWatcherDelegate?
    private let notificationPort = IONotificationPortCreate(kIOMasterPortDefault)
    private var removedIterator: io_iterator_t = 0
    
    public init(delegate: USBWatcherDelegate) {
        self.delegate = delegate
        
        func handleNotification(instance: UnsafeMutableRawPointer?, _ iterator: io_iterator_t) {
            let watcher = Unmanaged<USBWatcher>.fromOpaque(instance!).takeUnretainedValue()
            let handler: ((io_iterator_t) -> Void)?
            switch iterator {
            case watcher.removedIterator: handler = watcher.delegate?.deviceRemoved
            default: assertionFailure("received unexpected IOIterator"); return
            }
            while case let device = IOIteratorNext(iterator), device != IO_OBJECT_NULL {
                handler?(device)
                IOObjectRelease(device)
            }
        }
        
        //Specific to serial device
        let query = IOServiceMatching(kIOSerialBSDServiceValue)
        let opaqueSelf = Unmanaged.passUnretained(self).toOpaque()
        
        // Watch for disconnected devices.
        IOServiceAddMatchingNotification(notificationPort, kIOTerminatedNotification, query, handleNotification, opaqueSelf, &removedIterator)
        
        handleNotification(instance: opaqueSelf, removedIterator)
        
        // Add the notification to the main run loop to receive future updates.
        CFRunLoopAddSource(
            CFRunLoopGetMain(),
            IONotificationPortGetRunLoopSource(notificationPort).takeUnretainedValue(),
            .commonModes)
    }
    
    deinit {
        IOObjectRelease(removedIterator)
        IONotificationPortDestroy(notificationPort)
    }
}
