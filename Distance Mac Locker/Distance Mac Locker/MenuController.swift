//
//  MenuController.swift
//  Distance Mac Locker
//
//  Created by Yeo Kheng Meng on 7/1/17.
//  Copyright © 2017 Yeo Kheng Meng. All rights reserved.
//

import Cocoa

class MenuController: NSObject, NSMenuDelegate, NSApplicationDelegate, NSUserNotificationCenterDelegate, USBWatcherDelegate {
    
    let DISTANCE_MINIMUM: Int = 10
    let DISTANCE_MAXIMUM: Int = 80
    
    let DELAY_BEFORE_NOTIFICATION_AFTER_LOCK: UInt32 = 2
    
    
    let MENU_TITLE_NOT_CONNECTED = "NC"
    let MENU_ITEM_NO_PORTS_FOUND = "No Serial Ports found."
    let URL_SOURCE_CODE = "https://github.com/yeokm1/distance-machine-locker"
    
    
    let KEY_STORE_CONNECT_ON_START = "connectOnStart"
    let KEY_STORE_FLASH_BEFORE_CONNECT = "flashBeforeConnect"
    
    let TEXT_LOCKING_MODE_ON = "Locking Mode: On"
    let TEXT_LOCKING_MODE_OFF = "Locking Mode: Off"
    
    let TEXT_CONNECT_ON_START_ON = "Connect on Start: On"
    let TEXT_CONNECT_ON_START_OFF = "Connect on Start: Off"
    
    let TEXT_FLASH_BEFORE_CONNECT_ON = "Flash before Connect: On"
    let TEXT_FLASH_BEFORE_CONNECT_OFF = "Flash before Connect: Off"
    
    let TEXT_AUTO_CONNECT = "Auto-connect to: %@"
    let TEXT_AUTO_CONNECT_NA = "Auto-connect to: ---"
    
    let statusItem = NSStatusBar.system().statusItem(withLength: NSSquareStatusItemLength)
    
    @IBOutlet weak var statusMenu: NSMenu!
    @IBOutlet weak var serialPortMenu: NSMenu!
    @IBOutlet weak var distanceMenu: NSMenu!
    @IBOutlet weak var lockingTimeoutMenu: NSMenu!
    @IBOutlet weak var versionItem: NSMenuItem!
    @IBOutlet weak var lockingModeItem: NSMenuItem!
    @IBOutlet weak var connectOnStartItem: NSMenuItem!
    @IBOutlet weak var flashBeforeConnectItem: NSMenuItem!
    @IBOutlet weak var autoConnectToItem: NSMenuItem!
    
    var distanceSensor: DistanceSensor?
    
    var currentLockingDistance: Int!
    
    var lockingMode: Bool = true
    var connectOnStart: Bool = false
    var flashBeforeConnect: Bool = false
    
    var lastConnectedPort: String?
    var usbWatcher: USBWatcher!
    
    let locking: Locking = Locking()
    var lockingTimeout: Int = 1
    var goingToLock: Bool = false
    var timeOfLockWindowStart: CFAbsoluteTime!
    
    override func awakeFromNib() {
        
        statusItem.menu = statusMenu
        
        let appVersionString: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        
        versionItem.title = "Version: " + appVersionString
        
        currentLockingDistance = locking.getLockingDistance()
        lockingTimeout = locking.getLockingTimeout()
        
        connectOnStart = getConnectOnStart()
        flashBeforeConnect = getFlashBeforeConnect()
        
        
        setMenuTitleToNotConnected()
        refreshLockingModeText()
        refreshConnectOnStartText()
        refreshFlashBeforeConnectText()
        
        serialPortMenu.delegate = self
        distanceMenu.delegate = self
        lockingTimeoutMenu.delegate = self
        
        usbWatcher = USBWatcher(delegate: self)
        
        if connectOnStart{
            DispatchQueue.global(qos: .userInitiated).async {
                self.autoConnectOnStart()
            }
        }
        
    }
    
    func refreshFlashBeforeConnectText(){
        if flashBeforeConnect{
            flashBeforeConnectItem.title = TEXT_FLASH_BEFORE_CONNECT_ON
        } else {
            flashBeforeConnectItem.title = TEXT_FLASH_BEFORE_CONNECT_OFF
        }
        
    }
    
    func refreshConnectOnStartText(){
        if connectOnStart{
            connectOnStartItem.title = TEXT_CONNECT_ON_START_ON
        } else {
            connectOnStartItem.title = TEXT_CONNECT_ON_START_OFF
        }
        
    }
    
    func refreshLockingModeText(){
        
        if lockingMode{
            lockingModeItem.title = TEXT_LOCKING_MODE_ON
        } else {
            lockingModeItem.title = TEXT_LOCKING_MODE_OFF
        }
    }
    
    func refreshAutoConnectText(){
        DispatchQueue.global(qos: .userInitiated).async {
            if self.lastConnectedPort == nil {
                self.autoConnectToItem.title = self.TEXT_AUTO_CONNECT_NA
            } else {
                self.autoConnectToItem.title = String(format: self.TEXT_AUTO_CONNECT, self.lastConnectedPort!)
            }
        }
        
    }
    
    func setMenuTitleToNotConnected(){
        
        DispatchQueue.main.async {
            self.statusItem.title = self.MENU_TITLE_NOT_CONNECTED
        }
    }
    
    func distanceMenuItemClicked(item : NSMenuItem){
        
        let distanceStr: String = item.title
        
        if let distance = Int(distanceStr){
            currentLockingDistance = distance
            locking.setLockingDistance(newDistance: distance)
            
        }
    }
    
    func menuNeedsUpdate(_ menu: NSMenu) {
        
        if menu.isEqual(serialPortMenu){
            serialPortMenu.removeAllItems()
            
            let serialPortsFound: [String] = getPossibleArduinoPorts()
            print(serialPortsFound)
            
            if serialPortsFound.isEmpty{
                
                
                let emptyMenuItem = NSMenuItem(title: MENU_ITEM_NO_PORTS_FOUND, action: nil, keyEquivalent: "")
                emptyMenuItem.isEnabled = false
                serialPortMenu.addItem(emptyMenuItem)
            } else {
                
                if (distanceSensor != nil){
                    let disconnectMenuItem = NSMenuItem(title: "Disconnect", action: #selector(disconnectMenuItemClicked), keyEquivalent: "")
                    
                    disconnectMenuItem.target = self
                    serialPortMenu.addItem(disconnectMenuItem)
                    serialPortMenu.addItem(NSMenuItem.separator())
                }
                
                let connectedPortName = distanceSensor?.portName
                
                for portName in serialPortsFound{
                    let portMenuItem = NSMenuItem(title: portName, action: #selector(portMenuItemClicked), keyEquivalent: "")
                    
                    //Tick the currently connected port and disallow clicking on it
                    if connectedPortName != nil && portName.isEqual(connectedPortName){
                        portMenuItem.state = NSOnState
                    } else {
                        portMenuItem.target = self
                    }
                    serialPortMenu.addItem(portMenuItem)
                }
            }
            
        } else if(menu.isEqual(distanceMenu)){
            distanceMenu.removeAllItems()
            
            for distance in stride(from: DISTANCE_MINIMUM, through: DISTANCE_MAXIMUM, by: 5) {
                let distanceMenuItem = NSMenuItem(title: String(distance), action: #selector(distanceMenuItemClicked), keyEquivalent: "")
                
                distanceMenuItem.target = self
                
                
                if distance == currentLockingDistance{
                    distanceMenuItem.state = NSOnState
                }
                
                distanceMenu.addItem(distanceMenuItem)
            }
            
        } else if(menu.isEqual(lockingTimeoutMenu)) {
            lockingTimeoutMenu.removeAllItems()
            
            let options = ["0", "1", "3", "5"]
            
            for second in options {
                let timeoutMenuItem = NSMenuItem(title: String(second), action: #selector(timeoutMenuItemClicked), keyEquivalent: "")
                timeoutMenuItem.target = self
                if second == String(self.lockingTimeout) {
                    timeoutMenuItem.state = NSOnState
                }
                
                lockingTimeoutMenu.addItem(timeoutMenuItem)
            }
        }
        
    }
    
    func timeoutMenuItemClicked(item: NSMenuItem) {
        if let timeout = Int(item.title) {
            self.lockingTimeout = timeout
            locking.setLockingWindowTimeout(newTimeout: timeout)
        }
    }
    
    
    
    func portMenuItemClicked(item: NSMenuItem){
        let portName: String = item.title
        
        print("Serial port clicked: " + portName)
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.connectToThisPort(portName: portName)
        }
        
        
    }
    
    
    func disconnectMenuItemClicked(item: NSMenuItem){
        
        //This is a manual disconnect. We don't auto connect back when the device comes back into view
        lastConnectedPort = nil
        refreshAutoConnectText()
        
        disconnectExistingConnection(sendNotification: true)
    }
    
    func portError(errorMessage : String, portName: String){
        print(errorMessage)
        
        
        if distanceSensor != nil && distanceSensor!.portName.isEqual(portName){
            
            disconnectExistingConnection(sendNotification: false)
            
            if lockingMode{
                locking.lockMachine()
                
                //Allow time for machine to lock before engaging the notification
                sleep(DELAY_BEFORE_NOTIFICATION_AFTER_LOCK)
            }
            
            showAppNotification(subtitle: "Error in connection with " + portName, informativeText: errorMessage)
            
        }
        
        
    }
    
    func disconnectExistingConnection(sendNotification: Bool){
        
        setMenuTitleToNotConnected()
        
        if distanceSensor != nil{
            
            let existingConnectPortName = distanceSensor!.portName
            
            distanceSensor!.stopReceiving()
            distanceSensor = nil
            
            
            if sendNotification{
                showAppNotification(subtitle: "Disconnected from: " + existingConnectPortName, informativeText: nil)
            }
            
            
        }
        
        
    }
    
    //This function should be run from a separate thread
    func connectToThisPort(portName : String){
        
        //Remember the last connected port so we can auto connect later
        lastConnectedPort = portName
        refreshAutoConnectText()
        
        disconnectExistingConnection(sendNotification: true)
        distanceSensor = DistanceSensor(port: portName)
        
        if flashBeforeConnect{
            showAppNotification(subtitle: "Flashing Arduino: " + portName, informativeText: nil)
            let flashStatus = distanceSensor!.flashHexToArduino()
            
            if flashStatus.success == false{
                showAppNotification(subtitle: "Flashing failed" + portName, informativeText: flashStatus.error)
                distanceSensor = nil
                return
            }
            
        }
        
        
        let connectionStatus = distanceSensor!.startReceiving(callback: distanceReceived, portError: portError)
        
        if connectionStatus.connectionState {
            showAppNotification(subtitle: "Connected to: " + portName, informativeText: nil)
            print("Connect success")
        } else {
            showAppNotification(subtitle: "Failed to connect: " + portName, informativeText: connectionStatus.errorMessage)
            distanceSensor = nil
            print("Connect failed")
        }
        
    }
    
    func autoConnectOnStart(){
        let serialPortsFound: [String] = getPossibleArduinoPorts()
        
        if(serialPortsFound.isEmpty){
            showAppNotification(subtitle: "No serial modems found", informativeText: "Connect the sensor and open the port manually")
        } else if(serialPortsFound.count == 1){
            connectToThisPort(portName: serialPortsFound[0])
        } else {
            showAppNotification(subtitle: "Multiple serial USB modems found", informativeText: "Manually select the USB modem port to connect")
        }
        
    }
    
    func distanceReceived(distance: Int){
        DispatchQueue.main.async {
            let distanceText = String(distance)
            
            if self.lockingMode{
                self.statusItem.title = distanceText
            } else {
                let attributedDistanceString = NSAttributedString(
                    string: distanceText,
                    attributes: [NSFontAttributeName: NSFont.systemFont(ofSize: NSFont.systemFontSize()),NSBackgroundColorAttributeName: NSColor.red])
                self.statusItem.attributedTitle = attributedDistanceString
            }
        }
        if lockingMode && distance >= currentLockingDistance {
            if goingToLock == false {
                goingToLock = true
                // Showing Notification takes more than one second
                if lockingTimeout > 1 {
                    showAppNotification(subtitle: "Going away from your desk?", informativeText: "Locking in \(lockingTimeout) seconds")
                }
                startLockingWindow(start: true)
            } else {
                startLockingWindow(start: false)
            }
        } else {
            goingToLock = false
        }
    }
    
    func startLockingWindow(start: Bool) {
        if start {
            timeOfLockWindowStart = CFAbsoluteTimeGetCurrent()
        } else {
            let elapsed = CFAbsoluteTimeGetCurrent() - timeOfLockWindowStart
            if elapsed >= Double(lockingTimeout) {
                locking.lockMachine()
            }
        }
    }
    
    @IBAction func flashBeforeConnectClicked(_ sender: NSMenuItem) {
        flashBeforeConnect = !flashBeforeConnect
        setFlashBeforeConnect(flashBeforeConnect: flashBeforeConnect)
        refreshFlashBeforeConnectText()
    }
    
    @IBAction func connectOnStartClicked(_ sender: NSMenuItem) {
        connectOnStart = !connectOnStart
        setConnectOnStart(connectOnStart: connectOnStart)
        refreshConnectOnStartText()
    }
    
    //Referenced from: http://stackoverflow.com/questions/26704852/osx-swift-open-url-in-default-browser
    @IBAction func sourceURLClicked(_ sender: NSMenuItem) {
        if let url = URL(string: URL_SOURCE_CODE) {
            NSWorkspace.shared().open(url)
        }
    }
    
    @IBAction func lockingModeItemClicked(_ sender: NSMenuItem) {
        lockingMode = !lockingMode
        refreshLockingModeText()
    }
    
    @IBAction func quitClicked(_ sender: NSMenuItem) {
        NSApplication.shared().terminate(self)
    }
    
    
    func showAppNotification(subtitle: String?, informativeText: String?){
        showNotification(title: "Distance Mac Locker", subtitle: subtitle, informativeText: informativeText, contentImage: nil)
    }
    
    func showNotification(title: String, subtitle: String?, informativeText: String?, contentImage: NSImage?) -> Void {
        
        let notification = NSUserNotification()
        
        notification.title = title
        notification.subtitle = subtitle
        notification.informativeText = informativeText
        notification.contentImage = contentImage
        notification.soundName = NSUserNotificationDefaultSoundName
        
        NSUserNotificationCenter.default.deliver(notification)
        
    }
    
    
    func getConnectOnStart() -> Bool{
        let defaults = UserDefaults.standard
        
        let storedValue = defaults.bool(forKey: KEY_STORE_CONNECT_ON_START)
        
        return storedValue
    }
    
    func setConnectOnStart(connectOnStart: Bool){
        let defaults = UserDefaults.standard
        defaults.set(connectOnStart, forKey: KEY_STORE_CONNECT_ON_START)
        
    }
    
    func getFlashBeforeConnect() -> Bool{
        let defaults = UserDefaults.standard
        let storedValue = defaults.bool(forKey: KEY_STORE_FLASH_BEFORE_CONNECT)
        return storedValue
    }
    
    func setFlashBeforeConnect(flashBeforeConnect: Bool){
        let defaults = UserDefaults.standard
        defaults.set(flashBeforeConnect, forKey: KEY_STORE_FLASH_BEFORE_CONNECT)
        
    }
    
    public func deviceAdded(_ device: io_object_t) {
        let portNameOfAttached = getPortNameFromDevice(device)
        print("Device added: \(portNameOfAttached)")
        
        if portNameOfAttached == lastConnectedPort {
            DispatchQueue.global(qos: .userInitiated).async {
                self.connectToThisPort(portName: portNameOfAttached)
            }
        }
        
    }
    
    public func deviceRemoved(_ device: io_object_t) {
        //Not implemented here
    }
    
}
