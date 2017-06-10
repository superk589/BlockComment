//
//  SourceEditorCommand.swift
//  BlockCommentExtension
//
//  Created by zzk on 2017/5/30.
//  Copyright © 2017年 zzk. All rights reserved.
//

import Foundation
import XcodeKit

class SourceEditorCommand: NSObject, XCSourceEditorCommand {
    
    
    func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void ) -> Void {
        // Implement your command here, invoking the completion handler when done. Pass it nil on success, and an NSError on failure.
        
        print("--------------command start--------------")
        let buffer = invocation.buffer
        let selections = buffer.selections
        let lines = buffer.lines
        let indentationCharacter: Character = buffer.usesTabsForIndentation ? "\t" : " "

        guard let startRange = selections.firstObject as? XCSourceTextRange,
            let endRange = selections.lastObject as? XCSourceTextRange else {
                return
        }
        print("start at \(startRange)")
        print("end at \(endRange)")
        
        let startLine = startRange.start.line
        
        if endRange.end.column == 0 {
            endRange.end.line -= 1
            endRange.end.column = (lines.object(at: endRange.end.line) as? String)?.characters.count ?? 0
        }
        let endLine = endRange.end.line

        guard let startString = buffer.lines.object(at: max(0, startLine)) as? String,
            let endString = buffer.lines.object(at: min(endLine, buffer.lines.count - 1)) as? String,
            let preString = buffer.lines.object(at: max(0, startLine - 1)) as? String,
            let postString = buffer.lines.object(at: min(endLine + 1, buffer.lines.count - 1)) as? String
            else {
                return
        }
        
        print("startLine is \(startString)")
        print("endLine is \(endString)")
        print("preLine is \(preString)")
        print("postLine is \(postString)")

        let commented: Bool
        let surrounded: Bool
        
        if startString.characters.drop(while: { (c) -> Bool in
            c == indentationCharacter
        }).starts(with: "/*".characters) && endString.characters.drop(while: { (c) -> Bool in
            c == indentationCharacter
        }).starts(with: "*/".characters) {
            commented = true
            surrounded = false
        } else if preString.characters.drop(while: { (c) -> Bool in
            c == indentationCharacter
        }).starts(with: "/*".characters) && postString.characters.drop(while: { (c) -> Bool in
            c == indentationCharacter
        }).starts(with: "*/".characters) {
            commented = true
            surrounded = true
        } else {
            commented = false
            surrounded = false
        }
        
        print("commented \(commented)")
        print("surrounded \(surrounded)")
    
        if commented {
            
            if surrounded {
                lines.removeObject(at: endLine + 1)
                lines.removeObject(at: startLine - 1)
            } else {
                let start = lines.object(at: startLine) as! NSString
                lines[startLine] = start.replacingOccurrences(of: "/*", with: "")
                let end = lines.object(at: endLine) as! NSString
                lines[endLine] = end.replacingOccurrences(of: "*/", with: "")
            }
            
        } else {
            
            var numberOfIndentationCharacter = Int.max
            for index in startLine...endLine {
                if let line = lines.object(at: index) as? String {
                    numberOfIndentationCharacter = min(line.characters.prefix{ [" ", "\t"].contains($0) }.reduce(0){ $0 + ($1 == "\t" ? buffer.tabWidth : 1) }, numberOfIndentationCharacter)
                }
            }
            
            let prefix: String
            
            if buffer.usesTabsForIndentation {
                prefix = String(Array<Character>.init(repeating: "\t", count: numberOfIndentationCharacter / buffer.tabWidth)) + String(Array<Character>.init(repeating: " ", count: numberOfIndentationCharacter % buffer.tabWidth))
            } else {
                prefix = String(Array<Character>.init(repeating: " ", count: numberOfIndentationCharacter))
            }
            
            
            print("insert \"\(prefix)*/\"at line \(endLine + 1)")
            lines.insert("\(prefix)*/", at: endLine + 1)
            print("insert \"\(prefix)/*\"at line \(startLine)")
            lines.insert("\(prefix)/*", at: startLine)
            
            if startRange.start.column == 0 {
                startRange.start.line += 1
            }
            
        }
        
        print("--------------command end--------------")
    
        completionHandler(nil)
    }
    
}
