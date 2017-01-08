//
//  DistanceSensor.swift
//  Distance Mac Locker
//
//  Created by Yeo Kheng Meng on 7/1/17.
//  Copyright © 2017 Yeo Kheng Meng. All rights reserved.
//

import Cocoa

let FILENAME_ARDUINO_HEX = "distance-machine-locker-arduino"
let TEMP_PATHNAME_ARDUINO_HEX = "/tmp/" + FILENAME_ARDUINO_HEX
let TEMP_PATH_HEX_TYPE = "hex"

let TEMP_FULLPATH_ARDUINO_HEX = TEMP_PATHNAME_ARDUINO_HEX + "." + TEMP_PATH_HEX_TYPE

class DistanceSensor: NSObject {
    
    
    //Beyond this distance, the value is discarded
    //To guard against the case where the two numbers are read together in the serial port
    let DISTANCE_MAXIMUM_ALLOWABLE: Int = 150
    
    let COMM_BAUD_RATE : BaudRate = BaudRate.baud9600
    
    

    let COMMAND_AVRDUDE_PATH: String = "/Applications/Arduino.app/Contents/Java/hardware/tools/avr/bin/avrdude"
    
    var COMMAND_AVRDUDE_ARGS: [String] = ["-C", "/Applications/Arduino.app/Contents/Java/hardware/tools/avr/etc/avrdude.conf", "-p", "atmega328p" ,"-b", "115200", "-c", "arduino", "-U", "flash:w:" + TEMP_FULLPATH_ARDUINO_HEX + ":i", "-P"]
    
    
    
    var portName: String
    var serialPort: SerialPort
    
    var isReceiving: Bool = false
    
    var distanceCallback: ((_ distance: Int) -> Void)?
    var portErrorCallback: ((_ errorMessage: String, _ portName: String)-> Void)?
    
    public init(port : String){
        portName = port
        serialPort = SerialPort(path: portName)
        COMMAND_AVRDUDE_ARGS.append(portName)

    }
    
    
    public func flashHexToArduino() -> (success: Bool, error: String){
        print("Upload hex file to temp directory")
        
        if let internalFilePath = Bundle.main.path(forResource: FILENAME_ARDUINO_HEX, ofType: TEMP_PATH_HEX_TYPE){
            
            let filemgr = FileManager.default
            
            do {
                
                if filemgr.fileExists(atPath: TEMP_FULLPATH_ARDUINO_HEX){
                    try filemgr.removeItem(atPath: TEMP_FULLPATH_ARDUINO_HEX)
                }

                try filemgr.copyItem(atPath: internalFilePath, toPath: TEMP_FULLPATH_ARDUINO_HEX)
                print("Copy successful")
                
                print("Programming Arduino now")
                _ = runCommand(cmd: COMMAND_AVRDUDE_PATH, args: COMMAND_AVRDUDE_ARGS)
                print("Arduino programmed completed")
            
            } catch let error {
                return (false, error.localizedDescription)
            }
            

            
        }
        
        return (true, "")

    }
    
    
    public func startReceiving(callback : @escaping (_ distance : Int)-> Void, portError : @escaping (_ errorMessage: String, _ portName: String)-> Void) -> (connectionState: Bool, errorMessage: String){
        
        do{
            try serialPort.openPort(toReceive: true, andTransmit: false)
            serialPort.setSettings(receiveRate: COMM_BAUD_RATE, transmitRate: COMM_BAUD_RATE, minimumBytesToRead: 1)
            
            
            isReceiving = true
            distanceCallback = callback
            portErrorCallback = portError
            
            DispatchQueue.global(qos: .userInitiated).async {
                self.backgroundReadPort()
            }
            
            DispatchQueue.global(qos: .userInitiated).async {
                self.backgroundCheckPortOpen()
            }
            
        } catch PortError.failedToOpen {
            return (false, "Port failed to open")
        } catch {
            return (false, error.localizedDescription)
        }
        
        return (true, "")
    
    }
    
    
    public func stopReceiving(){
        isReceiving = false
        serialPort.closePort()
    }
    
    
    private func backgroundReadPort(){
        
        do{
            while isReceiving{
                var lineRead : String = try serialPort.readLine()
                
                lineRead = lineRead.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

                if let distanceNum = Int(lineRead) {
                    
                    if distanceCallback != nil && distanceNum < DISTANCE_MAXIMUM_ALLOWABLE{
                        distanceCallback!(distanceNum)
                    }

                }
                
            }

        } catch {
            if portErrorCallback != nil{
                portErrorCallback!(error.localizedDescription, portName)
            }
        }

    }
    
    
    //Check for existence of this ports
    private func backgroundCheckPortOpen(){
        
        while isReceiving{
            
            sleep(1)
            let availablePorts : [String] = getPossibleArduinoPorts()
            
            if !availablePorts.contains(portName){
                
                isReceiving = false
                
                if portErrorCallback != nil{
                    portErrorCallback!("Port Disconnected", portName)
                }
                
            }

        }
    }
    

}
