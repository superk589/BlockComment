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
    
    private func removeComment(in lines: NSMutableArray, atIndex index: Int) {
        guard let line = lines.object(at: index) as? NSString else { return }
        let newLine = line.replacingOccurrences(of: "*/", with: "").replacingOccurrences(of: "/*", with: "")
        if newLine.isEmptyLine {
            lines.removeObject(at: index)
        } else {
            lines[index] = newLine
        }
    }
    
    func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void ) -> Void {
        // Implement your command here, invoking the completion handler when done. Pass it nil on success, and an NSError on failure.
        
        print("--------------command start--------------")
        let buffer = invocation.buffer
        let selections = buffer.selections
        let lines = buffer.lines

        guard let startRange = selections.firstObject as? XCSourceTextRange,
            let endRange = selections.lastObject as? XCSourceTextRange
        else {
            completionHandler(nil)
            return
        }
        
        let isEmptyRange = (selections.count == 1 && startRange.isEmpty)
        
        print("start at \(startRange)")
        print("end at \(endRange)")
        
        let startLine = startRange.start.line
        
        let endLine: Int
        if endRange.end.column == 0 && endRange.end.line > startLine {
            endLine = endRange.end.line - 1
        } else {
            endLine = endRange.end.line
        }
        
        guard let startString = buffer.lines.object(at: max(0, startLine)) as? String,
            let endString = buffer.lines.object(at: min(endLine, buffer.lines.count - 1)) as? String,
            let preString = buffer.lines.object(at: max(0, startLine - 1)) as? String,
            let postString = buffer.lines.object(at: min(endLine + 1, buffer.lines.count - 1)) as? String
        else {
            completionHandler(nil)
            return
        }
        
        print("startLine is \(startString)")
        print("endLine is \(endString)")
        print("preLine is \(preString)")
        print("postLine is \(postString)")

        let commented: Bool
        let surrounded: Bool
        
        if startString.drop(while: { (c) -> Bool in
            [" ", "\t"].contains(c)
        }).starts(with: "/*") && endString.drop(while: { (c) -> Bool in
            [" ", "\t"].contains(c)
        }).starts(with: "*/") {
            commented = true
            surrounded = false
        } else if preString.drop(while: { (c) -> Bool in
            [" ", "\t"].contains(c)
        }).starts(with: "/*") && postString.drop(while: { (c) -> Bool in
            [" ", "\t"].contains(c)
        }).starts(with: "*/") {
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
                removeComment(in: lines, atIndex: endLine + 1)
                removeComment(in: lines, atIndex: startLine - 1)
            } else {
                removeComment(in: lines, atIndex: endLine)
                removeComment(in: lines, atIndex: startLine)
            }
            
        } else {
            var numberOfIndentationCharacter = Int.max
            for index in startLine...endLine {
                if let line = lines.object(at: index) as? String {
                    if line == "\n" && startLine != endLine { continue }
                    numberOfIndentationCharacter = min(line.prefix{ [" ", "\t"].contains($0) }.reduce(0){ $0 + ($1 == "\t" ? buffer.tabWidth : 1) }, numberOfIndentationCharacter)
                }
            }
            
            var prefix: String
            if buffer.usesTabsForIndentation {
                prefix = Array<String>.init(repeating: "\t", count: numberOfIndentationCharacter / buffer.tabWidth).joined() + Array<String>.init(repeating: " ", count: numberOfIndentationCharacter % buffer.tabWidth).joined()
            } else {
                prefix = Array<String>.init(repeating: " ", count: numberOfIndentationCharacter).joined()
            }
            
            print("insert \"\(prefix)*/\"at line \(endLine + 1)")
            lines.insert("\(prefix)*/", at: endLine + 1)
            print("insert \"\(prefix)/*\"at line \(startLine)")
            lines.insert("\(prefix)/*", at: startLine)
            
            if startRange.start.column == 0 {
                startRange.start.line += 1
                if isEmptyRange {
                    endRange.end.line += 1
                }
            }

        }

        completionHandler(nil)
        
        print("final selections are \(selections)")
        
        print("--------------command end--------------")
    }
    
}

extension String {
    var isEmptyLine: Bool {
        var result = true
        for c in self {
            if ![" ", "\t", "\n"].contains(c) {
                result = false
                break
            }
        }
        return result
    }
}

extension XCSourceTextRange {
    var isEmpty: Bool {
        return start.column == end.column && start.line == end.line
    }
}
