//
//  Logger.swift
//  Sandbox
//
//  Created by Wataru Nagasawa on 11/1/18.
//  Copyright © 2018 junkapp. All rights reserved.
//

import Foundation
import os.log
import Crashlytics

extension OSLogType: CustomStringConvertible {

    public var description: String {
        switch self {
        case OSLogType.debug: return "🔹🔹🔹"
        case OSLogType.info: return "ℹ️ℹ️ℹ️"
        case OSLogType.error: return "‼️‼️‼️"
        case OSLogType.fault: return "😱😱😱"
        default: return "DEFAULT"
        }
    }
}

// https://github.com/mono0926/mono-kit/blob/master/Lib/Logger.swift
// https://gist.github.com/yoichitgy/8806a7da3a52d8e6f5207e6a1a11b5a8
// https://developer.apple.com/reference/os/logging
public struct Logger {

    private static let log = OSLog(subsystem: Constants.AppInfo.bundleIdentifier, category: "default")

    fileprivate init() {}

    /// Log something at the Debug log level for debug info.
    /// ✅ Console
    /// ❌ CLSLogv
    /// ❌ recordError
    /// ❌ assertionFailure
    public func debug(_ message: @autoclosure () -> Any?,
                      functionName: CustomStringConvertible = #function,
                      fileName: CustomStringConvertible = #file,
                      lineNumber: Int = #line) {
        doLog(message(), logType: .debug, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
    }

    /// Log something at the Info log level for trace info.
    /// ✅ Console
    /// ✅ CLSLogv
    /// ❌ recordError
    /// ❌ assertionFailure
    public func info(_ message: @autoclosure () -> Any?,
                     functionName: CustomStringConvertible = #function,
                     fileName: CustomStringConvertible = #file,
                     lineNumber: Int = #line) {
        doLog(message(), logType: .info, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
        doCLSLog(message(), logType: .info, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
    }

    /// Log something at the Error log level for handleable error.
    /// ✅ Console
    /// ✅ CLSLogv
    /// ❌ recordError
    /// ❌ assertionFailure
    public func error(_ message: @autoclosure () -> Any?,
                      functionName: CustomStringConvertible = #function,
                      fileName: CustomStringConvertible = #file,
                      lineNumber: Int = #line) {
        doLog(message(), logType: .error, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
        doCLSLog(message(), logType: .info, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
    }

    /// Log something at the Fault log level for unexpected error.
    /// ✅ Console
    /// ❌ CLSLogv
    /// ✅ recordError
    /// ✅ assertionFailure
    public func fault(_ message: @autoclosure () -> Any?,
                      functionName: CustomStringConvertible = #function,
                      fileName: CustomStringConvertible = #file,
                      lineNumber: Int = #line) {
        doLog(message(), logType: .fault, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
        doCLSRecordError(message(), functionName: functionName, fileName: fileName, lineNumber: lineNumber)
        doAssertionFailure(message())
    }

    public func `default`(_ message: @autoclosure () -> Any?,
                          functionName: CustomStringConvertible = #function,
                          fileName: CustomStringConvertible = #file,
                          lineNumber: Int = #line) {
        doLog(message(), logType: .default, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
    }

    fileprivate func doLog(_ message: @autoclosure () -> Any?,
                           logType: OSLogType,
                           functionName: CustomStringConvertible,
                           fileName: CustomStringConvertible,
                           lineNumber: Int) {
        let staticSelf = type(of: self)
        let log = staticSelf.log
        guard log.isEnabled(type: logType) else { return }
        guard let output = staticSelf.buildOutput(message(),
                                                  logType: logType,
                                                  functionName: functionName,
                                                  fileName: fileName,
                                                  lineNumber: lineNumber) else { return }
        os_log("%@", log: log, type: logType, output)
    }

    fileprivate func doCLSLog(_ message: @autoclosure () -> Any?,
                              logType: OSLogType,
                              functionName: CustomStringConvertible,
                              fileName: CustomStringConvertible,
                              lineNumber: Int) {
        let staticSelf = type(of: self)
        guard let output = staticSelf.buildOutput(message(),
                                                  logType: logType,
                                                  functionName: functionName,
                                                  fileName: fileName,
                                                  lineNumber: lineNumber) else { return }
        CLSLogv("%@", getVaList([output]))
    }

    fileprivate func doCLSRecordError(_ message: @autoclosure () -> Any?,
                                      functionName: CustomStringConvertible,
                                      fileName: CustomStringConvertible,
                                      lineNumber: Int) {
        let staticSelf = type(of: self)
        guard let error = staticSelf.buildError(message(),
                                                functionName: functionName,
                                                fileName: fileName,
                                                lineNumber: lineNumber) else { return }
        Crashlytics.sharedInstance().recordError(error)
    }

    fileprivate func doAssertionFailure(_ message: @autoclosure () -> Any?) {
        guard let message = message() else { return }
        assertionFailure(String(describing: message))
    }

    static func buildOutput(_ message: @autoclosure () -> Any?,
                            logType: OSLogType,
                            functionName: CustomStringConvertible,
                            fileName: CustomStringConvertible,
                            lineNumber: Int) -> String? {
        guard let message = message() else { return nil }
        return "[\(logType)] [\(threadName)] [\((String(describing: fileName) as NSString).lastPathComponent):\(lineNumber)] \(functionName) > \(message)"
    }

    static func buildError(_ message: @autoclosure () -> Any?,
                           functionName: CustomStringConvertible,
                           fileName: CustomStringConvertible,
                           lineNumber: Int) -> Error? {
        guard let message = message() else { return nil }
        return NSError(domain: "\(fileName):\(functionName)", code: lineNumber, userInfo: ["message": message])
    }

    private static var threadName: String {
        if Thread.isMainThread {
            return "main"
        }
        if let threadName = Thread.current.name, !threadName.isEmpty {
            return threadName
        }
        if let queueName = DispatchQueue.currentQueueLabel, !queueName.isEmpty {
            return queueName
        }
        return String(format: "[%p] ", Thread.current)
    }
}

fileprivate extension DispatchQueue {
    static var currentQueueLabel: String? {
        return String(validatingUTF8: __dispatch_queue_get_label(nil))
    }
}

public let log = Logger()
