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
        let buffer = invocation.buffer
        let selections = buffer.selections
        let lines = buffer.lines
        let indentationCharacter: Character = buffer.usesTabsForIndentation ? "\t" : " "

        guard let startRange = selections.firstObject as? XCSourceTextRange,
            let endRange = selections.lastObject as? XCSourceTextRange else {
                return
        }
        
        let startLine = startRange.start.line
        let endLine = endRange.end.line
        
        guard let startString = buffer.lines.object(at: max(0, startLine)) as? String,
            let endString = buffer.lines.object(at: min(endLine, buffer.lines.count - 1)) as? String,
            let preString = buffer.lines.object(at: max(0, startLine - 1)) as? String,
            let postString = buffer.lines.object(at: min(endLine + 1, buffer.lines.count - 1)) as? String
            else {
                return
        }
        
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
                    numberOfIndentationCharacter = min(line.characters.prefix{ $0 == indentationCharacter }.count, numberOfIndentationCharacter)
                }
            }
            let prefix = String(Array<Character>.init(repeating: indentationCharacter, count: numberOfIndentationCharacter))
            
            lines.insert("\(prefix)/*", at: startLine)
            lines.insert("\(prefix)*/", at: endLine + 2)
            
            startRange.start.line = min(endRange.end.line, startRange.start.line + 1)
//            startRange.end.line = min(startRange.end.line, startRange.start.line + 1)
            
//            endRange.start.line += 1
//            endRange.end.line += 1
            
        }
    
        completionHandler(nil)
    }
    
}
