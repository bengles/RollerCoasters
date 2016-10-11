//
//  FirstViewController.swift
//  rollercoaster
//
//  Created by Björn Englesson on 05/01/13.
//  Copyright © 2016 Björn Englesson. All rights reserved.
//

import UIKit
import CoreBluetooth

class FirstViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    var centralManager:CBCentralManager!
    var blueToothReady = false
    var adafruit:CBPeripheral!
    var uartUUID:String!
    var uartRUUID:String!
    var uartWUUID:String!
    var weight:Int = 0
    var weightPos = 0
    var calibratedWeight:Int = 0
    var initialized:Bool = false
    var zipWeight:Int = 170 * 3
    var acceptableError:Int = 255
    var writeCharacteristic:CBCharacteristic!
    var LED:Data!
    var message:NSString!
    var weights:[Int]!
    let averageNr:Int = 10
    var numberOfSips:Int = 1;
    
    @IBOutlet weak var WeightLabel: UILabel!
    @IBOutlet weak var DifferenceLabel: UILabel!
    @IBOutlet weak var GameText: UILabel!
    @IBOutlet weak var stepper: UIStepper!
    @IBOutlet weak var stepText: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        startUpCentralManager()
        uartUUID = "6E400001-B5A3-F393-E0A9-E50E24DCCA9E"
        uartWUUID = "6E400002-B5A3-F393-E0A9-E50E24DCCA9E"
        uartRUUID = "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"
        GameText.text = "Wait.."
        self.view.backgroundColor = UIColor.yellow
        message = "y"
        weights = Array(repeating: 0, count: averageNr)
        stepText.text = String(numberOfSips)
        stepper.value = 1;
    }
    
    @IBAction func stepperAction(_ sender: AnyObject) {
        message = "y"
        self.view.backgroundColor = UIColor.yellow
        sendMessage()
        GameText.text = "Drink!!"
        numberOfSips = Int(stepper.value)
        stepText.text = String(numberOfSips)
    }
    
    func startUpCentralManager() {
        print("Initializing central manager")
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    @IBAction func Calibrate(_ sender: AnyObject) {
        self.view.backgroundColor = UIColor.white
        if (initialized) {
            print("Calibrate yao")
        
            print(weight)
            
            GameText.text = "Drink 3 sips"
            
            calibratedWeight = weight;
        } else {
            print("Not initialized yet.")
        }
    }
    
    @IBAction func Red(_ sender: AnyObject) {
        self.view.backgroundColor = UIColor.red
        GameText.text = "You lost!"
        
        // Set LED color
        message = "r"
        
        sendMessage()
    }
    
    @IBAction func Green(_ sender: AnyObject) {
        self.view.backgroundColor = UIColor.green
        GameText.text = "You win!"
        
        // Set LED color
        message = "g"
        
        sendMessage()
    }
    
    @IBAction func Yellow(_ sender: AnyObject) {
        self.view.backgroundColor = UIColor.yellow
        GameText.text = "Drink!!"
        
        // Set LED color
        message = "y"
        
        sendMessage()
    }
    
    func sendMessage() {
        let data = NSData(bytes: message.utf8String, length: message.length)
        adafruit.writeValue(data as Data, for: writeCharacteristic, type: CBCharacteristicWriteType.withResponse)
    }
    
    @IBAction func Done(_ sender: AnyObject) {
        let w = calibratedWeight - weight
        DifferenceLabel.text = "\(w)";
        if(zipWeight - acceptableError < w && w < zipWeight + acceptableError) {
            self.view.backgroundColor = UIColor.green
            GameText.text = "You win!"
            
            // Set LED color
            message = "g"
        } else {
            self.view.backgroundColor = UIColor.green
            GameText.text = "You win!"
            
            // Set LED color
            message = "g"
        }
        let data = NSData(bytes: message.utf8String, length: message.length)
        adafruit.writeValue(data as Data, for: writeCharacteristic, type: CBCharacteristicWriteType.withResponse)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        
    }
    
    func discoverDevices() {
        print("discovering devices")
        centralManager.scanForPeripherals(withServices:nil, options: nil)
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any],
    rssi RSSI: NSNumber) {
        //print("Discovered \(peripheral.name)")
        if (peripheral.name == "Adafruit Bluefruit LE" && adafruit != peripheral) {
            adafruit = peripheral
            adafruit.delegate = self
            centralManager.connect(adafruit, options: nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("OMG IT JUST CONNETCED")
        //centralManager.stopScan()
        adafruit.discoverServices(nil)
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("checking state")
        switch (central.state) {
        case .poweredOff:
            print("CoreBluetooth BLE hardware is powered off")
            
        case .poweredOn:
            print("CoreBluetooth BLE hardware is powered on and ready")
            blueToothReady = true;
            
        case .resetting:
            print("CoreBluetooth BLE hardware is resetting")
            
        case .unauthorized:
            print("CoreBluetooth BLE state is unauthorized")
            
        case .unknown:
            print("CoreBluetooth BLE state is unknown");
            
        case .unsupported:
            print("CoreBluetooth BLE hardware is unsupported on this platform");
            
        }
        if blueToothReady {
            discoverDevices()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print(adafruit.services?.description)
        for service in adafruit.services! {
            if (service.uuid.uuidString == uartUUID) {
                adafruit.discoverCharacteristics(nil, for: service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print ("Did find characterstics!")
        for characteristic in service.characteristics! {
            if (characteristic.uuid.uuidString == uartRUUID ) {
                print("Matched characteristic")
                adafruit.setNotifyValue(true, for: characteristic)
            }
            if (characteristic.uuid.uuidString == uartWUUID) {
                writeCharacteristic = characteristic
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if (characteristic.value?.count != 20) {
            let str = String(data: characteristic.value!, encoding: String.Encoding.ascii)
            let w = Int(str!)!
            weights[weightPos % averageNr] = w
            weightPos += 1
            if weightPos >= averageNr {
                //weight = weights.sorted()[averageNr/2]
                weight = weights.reduce(0, +)/weights.count
                WeightLabel.text = String(weight)
                print(weight)
            }
            if weightPos == averageNr {
                initialized = true
                print("Initialized")
                GameText.text = "Calibrate"
            }
        }
    }
    
}
