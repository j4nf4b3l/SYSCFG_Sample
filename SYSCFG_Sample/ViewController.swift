//
//  ViewController.swift
//  SYSCFG_Sample
//
//  Created by Jan Fabel on 08.08.20.
//  Copyright © 2020 Jan Fabel. All rights reserved.
//

import Cocoa
import ORSSerial
class ViewController: NSViewController, ORSSerialPortDelegate {
    
    let ports = ORSSerialPortManager.shared().availablePorts
    var ports_array = [String]()
    
    func serialPortWasRemovedFromSystem(_ serialPort: ORSSerialPort) {
        print("Port disconnected")
    }
    

    var port = ORSSerialPortManager.shared().availablePorts[0]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        port = ORSSerialPortManager.shared().availablePorts[SelectPort.indexOfSelectedItem]
        let ports = ORSSerialPortManager.shared().availablePorts
        for port in ports {
        ports_array.append("\(port)")
        }
        SelectPort.removeAllItems()
        SelectPort.addItems(withTitles: ports_array)
        SelectPort.autoenablesItems = true
        print(ports_array)
        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBOutlet weak var SerialField: NSTextField!
    
    @IBAction func ReadSerial(_ sender: Any) {
        SerialField.stringValue = ""
        let descriptor = ORSSerialPacketDescriptor(prefixString: "syscfg", suffixString: "\n[", maximumPacketLength: 150, userInfo: nil)
        port.startListeningForPackets(matching: descriptor)
        let command = "syscfg print SrNm".data(using: .utf8)! + Data([0x0A])
        port.send(command)
        DispatchQueue.global(qos: .background).async {
            sleep(1)
            self.port.stopListeningForPackets(matching: descriptor)

        }
        }
    
    func serialPort(_ serialPort: ORSSerialPort, didReceivePacket packetData: Data, matching descriptor: ORSSerialPacketDescriptor) {
        let output = String(data: packetData, encoding: .utf8)
        if (output?.contains("SrNm"))!  {
            usleep(50000)
            var sn = output!
            sn = remove_the_fucking_chars(func_key: "SrNm", key: sn)
            sn = sn.replacingOccurrences(of: "Serial: ", with: "")
            sn.removeDangerousCharsForSYSCFG()
            SerialField.stringValue = sn
        }
    }
    
    @IBAction func WriteSerial(_ sender: Any) {
        var value = SerialField.stringValue
        value.removeDangerousCharsForSYSCFG()
        let command = "syscfg add SrNm \(value)".data(using: .utf8)! + Data([0x0A])
        port.send(command)
        print("Serial sent to device")
    }

    @IBOutlet weak var ConnectBTN: NSButton!
    @IBOutlet weak var SelectPort: NSPopUpButton!
    @IBAction func RefreshPortList(_ sender: Any) {
        ports_array.removeAll()
        let ports = ORSSerialPortManager.shared().availablePorts
        for port in ports {
        ports_array.append("\(port)")
        print(port)
        }
        SelectPort.removeAllItems()
        SelectPort.addItems(withTitles: ports_array)
        SelectPort.autoenablesItems = true
    }
    @IBAction func ConnectPort(_ sender: Any) {
        port = ORSSerialPortManager.shared().availablePorts[SelectPort.indexOfSelectedItem]
        port.baudRate = 115200
        port.delegate = self
        print(port.path)
            if (port.isOpen) {
                port.close()
                print("Serial connection closed")
                ConnectBTN.title = "Connect"
            } else {
                ConnectBTN.title = "Disconnect"
                port.open()
                print("Serial connection opened")
        }
    }
    
}

func remove_the_fucking_chars(func_key: String, key: String) -> String {
    var str = key
    if let index = str.endIndex(of: "\(func_key)\n") {
        let substring = str[index...]
        var restring = String(substring)
        restring.removeFirst()
        restring.removeLast(2)
        return restring
    } else {return "error"}
}

extension StringProtocol {
    func index<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> Index? {
        range(of: string, options: options)?.lowerBound
    }
    func endIndex<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> Index? {
        range(of: string, options: options)?.upperBound
    }
    func indices<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> [Index] {
        var indices: [Index] = []
        var startIndex = self.startIndex
        while startIndex < endIndex,
            let range = self[startIndex...]
                .range(of: string, options: options) {
                indices.append(range.lowerBound)
                startIndex = range.lowerBound < range.upperBound ? range.upperBound :
                    index(range.lowerBound, offsetBy: 1, limitedBy: endIndex) ?? endIndex
        }
        return indices
    }
    func ranges<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> [Range<Index>] {
        var result: [Range<Index>] = []
        var startIndex = self.startIndex
        while startIndex < endIndex,
            let range = self[startIndex...]
                .range(of: string, options: options) {
                result.append(range)
                startIndex = range.lowerBound < range.upperBound ? range.upperBound :
                    index(range.lowerBound, offsetBy: 1, limitedBy: endIndex) ?? endIndex
        }
        return result
    }
    
    
}

extension String {

    mutating func removeDangerousCharsForSYSCFG() {
        let characterSet: NSCharacterSet = NSCharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLKMNOPQRSTUVWXYZ0123456789-_:+").inverted as NSCharacterSet
        self = (self.components(separatedBy: characterSet as CharacterSet) as NSArray).componentsJoined(by: "")
    }
}
