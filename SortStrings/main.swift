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
      print("\u{001B}[;m\(message)")
    case .error:
      fputs("\u{001B}[0;31m\(message)\n", stderr)
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
  
  static func sortFile(at path: String) throws {
    let data = try String(contentsOfFile: path, encoding: .utf8)
    var strings = data.components(separatedBy: .newlines)
    
    strings = strings.flatMap({ (string) -> String? in
      let string = string.trimmingCharacters(in: .whitespacesAndNewlines)
      guard string.starts(with: "\"") && string.count > 6 /* ""=""; */ else {
        return nil
      }
      return string
    })
    
    strings.sort(by: { (a, b) -> Bool in
      return a.prefix(2) < b.prefix(2)
    })
    
    let string = strings.joined(separator: "\n")
    try string.write(toFile: path, atomically: true, encoding: .utf8)
  }
}

do {
  let path = try PathReader.readPath()
  try FileSorter.sortFile(at: path)
  Console.write("Strings file is sorted successfully.")
} catch {
  Console.write(error.localizedDescription, to: .error)
}