//
//  ASV - Autonomous {Smart, Simple, Self-Driving} Vehicle
//  Controller.swift
//
//  Copyright © 2020 the ASV team. See LICENSE.md for legal information.
//

import Foundation
import UIKit
import AVFoundation
import GameController


class Controller: ObservableObject   {
    static let sharedInstance = Controller()

    private(set) var steering: Float = 0.0
    private(set) var throttle: Float = 0.0
    private(set) var isValid = false
    var mode: Mode = .stop
    @Published private(set) var controllers: [GCController:String] = [:]

    private var nextControllerIndex: Int = 0
    private var activeController: GCController?


    init() {
         // Subscribe for game controller connect/disconnect notifications
        NotificationCenter.default.addObserver(forName: .GCControllerDidConnect, object: nil, queue: .main) { notification in
            if let ctrl = notification.object as? GCController {
                self.addController(ctrl)
            }
        }
        NotificationCenter.default.addObserver(forName: .GCControllerDidDisconnect, object: nil, queue: .main) { notification in
            if let ctrl = notification.object as? GCController {
                self.remove(ctrl)
            }
        }

        // add existing controllers
        for controller in GCController.controllers() {
            addController(controller)
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: .GCControllerDidConnect, object: nil)
        NotificationCenter.default.removeObserver(self, name: .GCControllerDidDisconnect, object: nil)
    }


    func addController(_ controller: GCController) {
        let name = "\(controller.vendorName ?? "unknown") #\(nextControllerIndex)"
        nextControllerIndex += 1

        if controller.extendedGamepad != nil {
            print("Extended game connected: \(name)")
            controllers[controller] = name
            if controllers.count == 1 {
                selectGameController()
            }
        } else if controller.microGamepad != nil {
            print("Micro game controller connected: \(name)")
        } else {
            print("Unknown game controller connected: \(name)")
        }
    }

    func remove(_ controller: GCController) {
        print("Game controller disconnected: \(String(describing: controllers[controller]))")
        controllers[controller] = nil
        if controller.playerIndex == .index1 {
            controller.playerIndex = .indexUnset
            activeController = nil
            isValid = false
            selectGameController()
        }
    }

    
    func selectGameController() {
        let keys = controllers.keys
        if !keys.isEmpty {
            activeController = keys.first
            activeController?.playerIndex = .index1
            print("Selected active game controller: \(String(describing: controllers[activeController!]))")
        }
    }

    
    func poll() {
        if let activeController = activeController, let extendedGamepad = activeController.extendedGamepad {
            isValid = true
            steering = extendedGamepad.rightThumbstick.xAxis.value
            let leftTrigger = extendedGamepad.leftTrigger.value
            let rightTrigger = extendedGamepad.rightTrigger.value
            throttle = (rightTrigger >= leftTrigger) ? rightTrigger : -leftTrigger
            if (extendedGamepad.buttonX.isPressed) {
                mode = .auto
            }
            if (extendedGamepad.buttonA.isPressed) {
                mode = .manual
            }
            if (extendedGamepad.buttonB.isPressed) {
                mode = .stop
            }
        } else {
            isValid = false
            steering = 0
            throttle = 0
            //mode = .stop
        }
        //print("controller=\(mode)")
    }
    
}
