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
    var weight:Int = 0
    var weights:[Int] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    var weightPos = 0
    var calibratedWeight:Int = 0
    var initialized:Bool = false
    var zipWeight:Int = 170 * 3
    var acceptableError:Int = 255
    
    @IBOutlet weak var WeightLabel: UILabel!
    @IBOutlet weak var DifferenceLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        startUpCentralManager()
        uartUUID = "6E400001-B5A3-F393-E0A9-E50E24DCCA9E"
        uartRUUID = "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"
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
        
            calibratedWeight = weight;
        } else {
            print("Not initialized yet.")
        }
    }
    
    @IBAction func Done(_ sender: AnyObject) {
        let w = calibratedWeight - weight
        DifferenceLabel.text = "\(w)";
        if(zipWeight - acceptableError < w && w < zipWeight + acceptableError) {
            self.view.backgroundColor = UIColor.green
        } else {
            self.view.backgroundColor = UIColor.red
        }
    }
    
    func discoverDevices() {
        print("discovering devices")
        centralManager.scanForPeripherals(withServices:nil, options: nil)
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any],
    rssi RSSI: NSNumber) {
        print("Discovered \(peripheral.name)")
        if (peripheral.name == "Adafruit Bluefruit LE" && adafruit != peripheral) {
            adafruit = peripheral
            adafruit.delegate = self
            centralManager.connect(adafruit, options: nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("OMG IT JUST CONNETCED")
        centralManager.stopScan()
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
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if (characteristic.value?.count != 20) {
            let str = String(data: characteristic.value!, encoding: String.Encoding.ascii)
            let w = Int(str!)!
            weights[weightPos % 10] = w
            weightPos += 1
            if weightPos >= 10 {
                weight = weights.sorted()[4]
                WeightLabel.text = String(weight)
            }
            if weightPos == 10 {
                initialized = true
                print("Initialized")
            }
        }
    }
    
}
