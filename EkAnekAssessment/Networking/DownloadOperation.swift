//
//  DownloadOperation.swift
//  EkAnekAssessment
//
//  Created by Ankit Batra on 12/09/20.
//  Copyright © 2020 EkAnek. All rights reserved.
//

import Foundation
import UIKit

class DownloadOperation: AsynchronousOperation {
    
    var task: URLSessionTask!
    
    init(url: URL) {
        super.init()
        
        let sessionConfiguration = URLSessionConfiguration.default
        let session: URLSession = URLSession(configuration: sessionConfiguration)
        task = session.downloadTask(with: url) { temporaryURL, response, error in
            defer {
                self.completeOperation()
            }
            guard error == nil && temporaryURL != nil else {
                print("error downloading image")
                return
            }
            
            do {
                //Saving the image to documents directory
                let manager = FileManager.default
                let documents = try manager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                let destinationURL = documents.appendingPathComponent(url.lastPathComponent)
                if manager.fileExists(atPath: destinationURL.path) {
                    try manager.removeItem(at: destinationURL)
                }
                try manager.moveItem(at: temporaryURL!, to: destinationURL)
                
            } catch let moveError {
                print(moveError)
            }
        }
    }
    
    override func cancel() {
        task.cancel()
        super.cancel()
    }
    
    override func main() {
        task.resume()
    }
    
}


/// Asynchronous operation base class
///
/// This is abstract to class performs all of the necessary KVN of `isFinished` and
/// `isExecuting` for a concurrent `Operation` subclass. You can subclass this and
/// implement asynchronous operations. All you must do is:
///
/// - override `main()` with the tasks that initiate the asynchronous task;
///
/// - call `completeOperation()` function when the asynchronous task is done;
///
/// - optionally, periodically check `self.cancelled` status, performing any clean-up
///   necessary and then ensuring that `completeOperation()` is called; or
///   override `cancel` method, calling `super.cancel()` and then cleaning-up
///   and ensuring `completeOperation()` is called.

public class AsynchronousOperation : Operation {
    
    override public var isAsynchronous: Bool { return true }
    
    private let stateLock = NSLock()
    
    private var _executing: Bool = false
    override private(set) public var isExecuting: Bool {
        get {
            return stateLock.withCriticalScope { _executing }
        }
        set {
            willChangeValue(forKey: "isExecuting")
            stateLock.withCriticalScope { _executing = newValue }
            didChangeValue(forKey: "isExecuting")
        }
    }
    
    private var _finished: Bool = false
    override private(set) public var isFinished: Bool {
        get {
            return stateLock.withCriticalScope { _finished }
        }
        set {
            willChangeValue(forKey: "isFinished")
            stateLock.withCriticalScope { _finished = newValue }
            didChangeValue(forKey: "isFinished")
        }
    }
    
    /// Complete the operation
    ///
    /// This will result in the appropriate KVN of isFinished and isExecuting
    
    public func completeOperation() {
        if isExecuting {
            isExecuting = false
        }
        
        if !isFinished {
            isFinished = true
        }
    }
    
    override public func start() {
        if isCancelled {
            isFinished = true
            return
        }
        
        isExecuting = true
        
        main()
    }
}

/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 An extension to `NSLock` to simplify executing critical code.
 
 From Advanced NSOperations sample code in WWDC 2015 https://developer.apple.com/videos/play/wwdc2015/226/
 From https://developer.apple.com/sample-code/wwdc/2015/downloads/Advanced-NSOperations.zip
 */

extension NSLock {
    
    /// Perform closure within lock.
    ///
    /// An extension to `NSLock` to simplify executing critical code.
    ///
    /// - parameter block: The closure to be performed.
    
    func withCriticalScope<T>(block: () -> T) -> T {
        lock()
        let value = block()
        unlock()
        return value
    }
}
