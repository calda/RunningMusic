//
//  MainViewController.swift
//  RunningMusic
//
//  Created by Cal on 10/10/15.
//  Copyright © 2015 Cal. All rights reserved.
//

import Foundation
import UIKit
import CoreMotion

var RMCurrentActivityState = ActivityState.Standing
enum ActivityState {
    case Standing, Walking, Running
}

class RunningViewController : UIViewController {
    
    var motion: CMMotionManager = CMMotionManager()
    
    var previousAccel: CMAcceleration?
    var motionConstantStack: [Double] = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
    var previous100Frames: [Double] = []
    
    @IBOutlet weak var stateLabel: UILabel!
    
    override func viewDidLoad() {
        startAccelerometerPolling()
    }
    
    func startAccelerometerPolling() {
        
        motion.startAccelerometerUpdatesToQueue(NSOperationQueue(), withHandler: { data, error in
            guard let data = data else { return }
            self.performAccelerometerCalculations(data)
        })
    }
    
    func restartAccelerometerPolling() {
        motion.stopAccelerometerUpdates()
        motion = CMMotionManager()
        startAccelerometerPolling()
    }
    
    func performAccelerometerCalculations(data: CMAccelerometerData) {
        let accel = data.acceleration
        if previousAccel == nil { previousAccel = accel }
        guard let previousAccel = previousAccel else { return }
        
        //calulations made according to the following publication:
        //ADVANCED PEDOMETER FOR SMARTPHONE-BASED ACTIVITY TRACKING
        //http://www2.fiit.stuba.sk/~bielik/publ/abstracts/2012/tomlein-et-al-healthinf2012.pdf
        
        let X = accel.x * previousAccel.x
        let Y = accel.y * previousAccel.y
        let Z = accel.z * previousAccel.z
        let rootCurrent = sqrt(pow(accel.x, 2) + pow(accel.y, 2) + pow(accel.z, 2))
        let rootPrevious = sqrt(pow(previousAccel.x, 2) + pow(previousAccel.y, 2) + pow(previousAccel.z, 2))
        
        let unweightedConstant = (X + Y + Z) / (rootCurrent * rootPrevious)
        
        var weightedTotal: Double = 10 * unweightedConstant
        for i in 1...9 {
            let weight = Double(10 - i)
            let constant = motionConstantStack[i]
            weightedTotal += constant * weight
        }
        
        let weightedConstant = abs(weightedTotal / 55.0)
        
        if weightedConstant < 0.1 {
            restartAccelerometerPolling()
        }
        
        print(weightedConstant)
        
        addConstantToMotionStack(weightedConstant)
        updateWalkRunState()
    }
    
    func addConstantToMotionStack(constant: Double) {
        for i in 0...8 {
            motionConstantStack[i] = motionConstantStack [i + 1]
        }
        motionConstantStack[9] = constant
        
        previous100Frames.append(constant)
        if previous100Frames.count >= 100 {
            previous100Frames.removeAtIndex(0)
        }
    }
    
    func updateWalkRunState() {
        var sum = 0.0
        var peak = -100.0
        var trough = 100.0
        
        for frame in previous100Frames {
            sum += frame
            if frame > peak { peak = frame }
            if frame < trough { trough = frame }
        }
        
        let average = sum / Double(previous100Frames.count)
        let highest = peak
        let lowest = trough
        
        //state updates accoring to Accelerometer Experiment.numbers in repository root
        
        if highest > 0.95 && lowest > 0.95 {
            RMCurrentActivityState = .Standing
        }
        
        else if highest > 0.8 && lowest < 0.8 {
            RMCurrentActivityState = .Walking
        }
        
        else if average < 0.7 && highest < 0.9 {
            RMCurrentActivityState = .Running
        }
        
        sync { self.stateLabel.text = "\(RMCurrentActivityState)" }
        
    }
    
}