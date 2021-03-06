//
//  main.swift
//  LocalizableMerge
//
//  Created by Goksel Koksal on 11/06/2018.
//  Copyright © 2018 Goksel Koksal. All rights reserved.
//

import Foundation

class Console {
  
  enum OutputType {
    case standard
    case error
  }
  
  static func write(_ message: String, to: OutputType = .standard) {
    switch to {
    case .standard:
      print("\(message)")
    case .error:
      fputs("\(message)\n", stderr)
    }
  }
}

class PathReader {
  
  enum Error: Swift.Error {
    case invalidPath
    case invalidFileFormat
  }
  
  static func readPath() throws -> String {
    let arguments = CommandLine.arguments
    
    if arguments.count == 2 {
      let path = arguments[1]
      try validatePath(path)
      return path
    } else {
      Console.write("Path of the file to sort:")
      if let path = readLine() {
        try validatePath(path)
        return path
      } else {
        throw Error.invalidPath
      }
    }
  }
  
  private static func validatePath(_ path: String) throws {
    if path.hasSuffix(".strings") == false {
      throw Error.invalidFileFormat
    }
  }
}

class FileSorter {
  
  enum Error: Swift.Error {
    
    case invalidContents(line: String)
    
    var localizedDescription: String {
      switch self {
      case .invalidContents(line: let line):
        return "Invalid contents. (Line: \(line))"
      }
    }
  }
  
  static func sortFile(at path: String) throws {
    // BRUTE FORCE APPROACH. PROCEED WITH CAUTION.
    // ...works for this scale!
    let data = try String(contentsOfFile: path, encoding: .utf8)
    var strings = data.components(separatedBy: .newlines)
    
    strings = strings.compactMap({ (string) -> String? in
      let string = string.trimmingCharacters(in: .whitespacesAndNewlines)
      guard string.starts(with: "\"") && string.count > 6 /* ""=""; */ else {
        return nil
      }
      return string
    })
    
    try strings.sort(by: { (line1, line2) -> Bool in
      guard let key1 = keyFromLine(line1) else {
        throw Error.invalidContents(line: line1)
      }
      guard let key2 = keyFromLine(line2) else {
        throw Error.invalidContents(line: line2)
      }
      return key1 < key2
    })
    
    let string = strings.joined(separator: "\n")
    try string.write(toFile: path, atomically: true, encoding: .utf8)
  }
  
  private static func keyFromLine(_ line: String) -> String? {
    guard let delimeterIndex = line.firstIndex(of: "=") else {
      return nil
    }
    let key = line[..<delimeterIndex].trimmingCharacters(in: CharacterSet.doubleQuotesAndWhitespace)
    return key
  }
}

extension CharacterSet {
  static let doubleQuotesAndWhitespace: CharacterSet = {
    var set = CharacterSet.whitespaces
    set.insert("\"")
    return set
  }()
}

do {
  let path = try PathReader.readPath()
  try FileSorter.sortFile(at: path)
  Console.write("File is sorted successfully. (\(path))")
} catch {
  Console.write("\(error)", to: .error)
}
