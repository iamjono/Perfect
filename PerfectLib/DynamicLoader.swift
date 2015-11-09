//
//  DynamicLoader.swift
//  PerfectLib
//
//  Created by Kyle Jessup on 7/13/15.
//	Copyright (C) 2015 PerfectlySoft, Inc.
//
//     This program is free software: you can redistribute it and/or modify
//     it under the terms of the GNU Affero General Public License as published by
//     the Free Software Foundation, either version 3 of the License, or
//     (at your option) any later version.
//
//     This program is distributed in the hope that it will be useful,
//     but WITHOUT ANY WARRANTY; without even the implied warranty of
//     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//     GNU Affero General Public License for more details.
//
//     You should have received a copy of the GNU Affero General Public License
//     along with this program.  If not, see <http://www.gnu.org/licenses/>.
//


import Foundation

class DynamicLoader {
	
	// sketchy! PerfectServerModuleInit is not defined as convention(c)
	// but it does not seem to matter provided it is Void->Void
	// I am unsure on how to convert a void* to a legit Swift ()->() func
	typealias InitFunction = @convention(c) ()->()
	
	let initFuncName = "PerfectServerModuleInit"
	
	init() {
		
	}
	
	func loadFramework(atPath: String) -> Bool {
		let resolvedPath = atPath.stringByResolvingSymlinksInPath
		let moduleName = resolvedPath.lastPathComponent.stringByDeletingPathExtension
		let file = File(resolvedPath + "/" + moduleName)
		if file.exists() {
			let realPath = file.realPath()
			let openRes = dlopen(realPath, RTLD_NOW|RTLD_LOCAL)
			if openRes != nil {
				// this is fragile
				let newModuleName = moduleName.stringByReplacingOccurrencesOfString("-", withString: "_").stringByReplacingOccurrencesOfString(" ", withString: "_")
				let symbolName = "_TF\(newModuleName.utf8.count)\(newModuleName)\(initFuncName.utf8.count)\(initFuncName)FT_T_"
				let sym = dlsym(openRes, symbolName)
				if sym != nil {
					let f: InitFunction = unsafeBitCast(sym, InitFunction.self)
					f()
					return true
				} else {
					print("Error loading \(atPath). Symbol \(symbolName) not found.")
					dlclose(openRes)
				}
			} else {
				print("Errno \(String.fromCString(dlerror())!)")
			}
		}
		return false
	}
}

