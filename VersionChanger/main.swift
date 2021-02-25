//
//  main.swift
//  VersionChanger
//
//  Created by Артeмий Шлесберг on 29.08.2020.
//  Copyright © 2020 Shlesberg. All rights reserved.
//

import Foundation

/*
 1) Find latest archive
 2) make a copy
 3) rename the copy
 4) change properties of vestion and build number
 5) save new content
 */

enum Errors: LocalizedError {
    var localizedDescription: String {
        switch self {
        case .wrongArguments:
            return "Version and build number should be specified: <version> <build number>"
        case .wronVersionFormat:
            return "Wron version fromat: should be #.#.#"
        case .wrongBuildNumberFormat:
            return "Wron version fromat: should be integer"
        case .noArchive:
            //TODO: Add path parameter
            return "There is no valid archive in the default directory"
        }
    }
    
    var errorDescription: String? {
        return self.localizedDescription
    }
    
    case wrongArguments
    case wronVersionFormat
    case wrongBuildNumberFormat
    case noArchive
}

let fileManager = FileManager.default

func archiveCreationDate(archiveURL: URL) throws -> Date {
    
    let folderPath = String(archiveURL.path)// .prefix( archiveURL.relativeString.count - 1))
    let attributes = try fileManager.attributesOfItem(atPath: folderPath)
    let date = attributes[FileAttributeKey.creationDate] as! Date
    
    return date
}

func latestItem(at directory: URL) throws -> URL {

    guard let latestURL = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: [URLResourceKey.nameKey, URLResourceKey.creationDateKey], options: .skipsHiddenFiles)
        .max(by: {
            return try archiveCreationDate(archiveURL: $0) < archiveCreationDate(archiveURL: $1)
        })
    else {
        print("no archive")
        throw Errors.noArchive
    }
    return latestURL
}



func checkVersionFormat(versionString: String) -> Bool {
    let components = versionString.split(separator: ".")
    
    guard components.count == 3 else {
        return false
    }
    
    guard
        let _ = Int(components[0]),
        let _ = Int(components[1]),
        let _ = Int(components[2]) else {
            return false
    }
    
    return true
}

func updateVersionProperty(plistURL: URL, version: String, buildNumber: String) throws -> Data{
    var propertyListFormat = PropertyListSerialization.PropertyListFormat.xml //Format of the Property List.
    var plistData: [String: AnyObject] = [:] //Our data
    let plistPath: String? = plistURL.path//Bundle.main.path(forResource: "data", ofType: "plist")! //the path of the data
    let plistXML = FileManager.default.contents(atPath: plistPath!)!
    //convert the data to a dictionary and handle errors.
    plistData = try PropertyListSerialization.propertyList(from: plistXML, options: .mutableContainersAndLeaves, format: &propertyListFormat) as! [String:AnyObject]
    
    if plistData.keys.contains("ApplicationProperties") {
        var properties = plistData["ApplicationProperties"] as! [String: String]
        
        properties["CFBundleShortVersionString"] = version
        properties["CFBundleVersion"] = buildNumber
        
        plistData["ApplicationProperties"] = properties as AnyObject
        
    } else {
        plistData["CFBundleShortVersionString"] = version as AnyObject
        plistData["CFBundleVersion"] = buildNumber as AnyObject
    }
    
    let data = try PropertyListSerialization.data(fromPropertyList: plistData, format: .xml, options: 0)
    
    return data
}




do {
    
    //Parsing arguments
    
    let arguments = CommandLine.arguments

    guard arguments.count == 3 else {
        throw Errors.wrongArguments
    }
    
    let version = arguments[1]
    guard checkVersionFormat(versionString: version) else {
        throw Errors.wronVersionFormat
    }
    
    let buildNuber = arguments[2]
    guard let _ = Int(buildNuber) else {
        throw Errors.wronVersionFormat
    }
    
    //Locating the archive
    
    let archivesPath = "/Users/artemijslesberg/Library/Developer/Xcode/Archives"

    //get last archives folder
    let url = URL(fileURLWithPath: archivesPath, isDirectory: true)
    
    let latestArchFolderURL = try latestItem(at: url)
    let latesArchiveURL = try latestItem(at: latestArchFolderURL)
    
    //creating copy of the archive
    let ext = latesArchiveURL.pathExtension
    let existingName = latesArchiveURL.deletingPathExtension().lastPathComponent
    
    let df = DateFormatter()
    df.dateFormat = "HH.mm"
    let newName = existingName.prefix(existingName.count - 5) + df.string(from: Date())
    
    let newArchURL = latesArchiveURL.deletingLastPathComponent().appendingPathComponent(String(newName)).appendingPathExtension(ext)
    
    try fileManager.copyItem(at: latesArchiveURL, to: newArchURL)
    
    //Getting first info.plist
    let firstPlistURL = newArchURL.appendingPathComponent("info.plist")
    
    let firstData = try updateVersionProperty(plistURL: firstPlistURL, version: version, buildNumber: buildNuber)
    try firstData.write(to: firstPlistURL)
    
    //getting second info.plyst inside dSYM
    let dSymsURL = newArchURL.appendingPathComponent("dSYMs")
    let folders = try fileManager.contentsOfDirectory(at: dSymsURL, includingPropertiesForKeys: [URLResourceKey.nameKey], options: .skipsHiddenFiles)
    let secondPlistURL = folders.first(where: { $0.lastPathComponent.contains("app") })!.appendingPathComponent("Contents/info.plist")
    
    let secondData = try updateVersionProperty(plistURL: secondPlistURL, version: version, buildNumber: buildNuber)
    try secondData.write(to: secondPlistURL)
    
} catch {
    print("Error: \(error.localizedDescription)")
}

struct a {
    var a: String
}

extension a {
    var b: Int {
        return 0
    }
}
