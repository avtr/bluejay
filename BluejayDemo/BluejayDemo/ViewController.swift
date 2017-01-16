//
//  ViewController.swift
//  BluejayDemo
//
//  Created by Jeremy Chiang on 2017-01-09.
//  Copyright © 2017 Steamclock Software. All rights reserved.
//

import UIKit
import Bluejay

let heartRateService = ServiceIdentifier(uuid: "180D")
let bodySensorLocation = CharacteristicIdentifier(uuid: "2A38", service: heartRateService)
let heartRate = CharacteristicIdentifier(uuid: "2A37", service: heartRateService)

class ViewController: UIViewController {

    private let bluejay = Bluejay.shared
    
    @IBOutlet var statusLabel: UILabel!
    @IBOutlet var deviceLabel: UILabel!
    @IBOutlet var bpmLabel: UILabel!
    @IBOutlet var logTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        bluejay.register(observer: self)
        bluejay.register(listenRestorable: self)
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.updateLog(notification:)), name: .logDidUpdate, object: nil)
    }
    
    func updateLog(notification: Notification) {
        DispatchQueue.main.async {
            if let logContent = notification.userInfo?[bluejayLogContent] as? String {
                self.logTextView.text = logContent
            }
        }
    }
    
    @IBAction func scan() {
        bluejay.scan(service: heartRateService) { (result) in
            switch result {
            case .success(let peripheral):
                print("Demo: Scan succeeded with peripheral: \(peripheral.name)")
            case .failure(let error):
                print("Demo: Scan failed with error: \(error.localizedDescription)")
            }
        }
    }
    
    @IBAction func read() {
        bluejay.read(from: bodySensorLocation) { (result: BluejayReadResult<IncomingString>) in
            switch result {
            case .success(let value):
                print("Demo: Read succeeded with value: \(value.string)")
            case .failure(let error):
                print("Demo: Read failed with error: \(error.localizedDescription)")
            }
        }
    }
    
    @IBAction func write() {
        bluejay.write(to: bodySensorLocation, value: OutgoingString("Wrist")) { (result) in
            switch result {
            case .success:
                print("Demo: Write succeeded.")
            case .failure(let error):
                print("Demo: Write failed with error: \(error.localizedDescription)")
            }
        }
    }
    
    @IBAction func listen() {
        bluejay.listen(to: heartRate) { (result: BluejayReadResult<IncomingInt>) in
            switch result {
            case .success(let value):
                print("Demo: Listen succeeded with value: \(value.int)")
            case .failure(let error):
                print("Demo: Listen failed with error: \(error.localizedDescription)")
            }
        }
    }
    
    @IBAction func cancelListen() {
        bluejay.cancelListen(to: heartRate)
    }
    
    @IBAction func crash() {
        kill(getpid(), SIGKILL)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

struct IncomingString: BluejayReceivable {
    
    var string: String
    
    init(bluetoothData: Data) {
        string = String(data: bluetoothData, encoding: .utf8)!
    }
    
}

struct OutgoingString: BluejaySendable {
    
    var string: String
    
    init(_ string: String) {
        self.string = string
    }
    
    func toBluetoothData() -> Data {
        return string.data(using: .utf8)!
    }
    
}

struct IncomingInt: BluejayReceivable {
    
    var int: Int
    
    init(bluetoothData: Data) {
        var value = 0
        
        (bluetoothData as NSData).getBytes(&value, range: NSRange(location: 0, length: 1))
        
        int = value
    }
    
}

extension ViewController: BluejayEventsObservable {
    
    func bluetoothAvailable(_ available: Bool) {
        DispatchQueue.main.async {
            self.statusLabel.text = available ? "Available" : "Not Available"
        }
    }
    
    func connected(_ peripheral: BluejayPeripheral) {
        DispatchQueue.main.async {
            self.deviceLabel.text = peripheral.name ?? "Connected"
        }
    }
    
    func disconected() {
        DispatchQueue.main.async {
            self.deviceLabel.text = "Disconnected"
        }
    }
    
}

extension ViewController: ListenRestorable {
    
    func didFindRestorableListen(on characteristic: CharacteristicIdentifier) -> Bool {
        return false
    }
    
}
