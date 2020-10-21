//
//  JavascriptAPIGlobal.swift
//  iina
//
//  Created by Collider LI on 20/10/2020.
//  Copyright © 2020 lhc. All rights reserved.
//

import Foundation
import JavaScriptCore

@objc protocol JavascriptAPIGlobalControllerExportable: JSExport {
  func createPlayerInstance(_ options: [String: Any]) -> Any
  func sendMessage(_ target: JSValue, _ name: String, _ data: JSValue)
  func onMessage(_ name: String, _ callback: JSValue)
}

@objc protocol JavascriptAPIGlobalChildExportable: JSExport {
  func sendMessage(_ name: String, _ data: JSValue)
  func onMessage(_ name: String, _ callback: JSValue)
}

class JavascriptAPIGlobalController: JavascriptAPI, JavascriptAPIGlobalControllerExportable {
  var instances: [Int: PlayerCore] = [:]
  private var instanceCounter = 0
  private var listeners: [String: JSManagedValue] = [:]

  func createPlayerInstance(_ options: [String: Any]) -> Any {
    // create the `PlayerCore` manually since it's managed directly by the plugin
    let pc = PlayerCore()
    pc.label = "\(instanceCounter)-\(pluginInstance.plugin.identifier)"
    pc.isManagedByPlugin = true
    pc.startMPV()
    if (options["enablePlugins"] as? Bool == true) {
      pc.loadPlugins()
    } else {
      // load the current plugin only.
      // `reloadPlugin` will create a plugin instance if it's not loaded.
      pc.reloadPlugin(pluginInstance.plugin)
    }
    instances[instanceCounter] = pc
    return instanceCounter
  }

  func sendMessage(_ target: JSValue, _ name: String, _ data: JSValue) {

  }

  func onMessage(_ name: String, _ callback: JSValue) {
    if let previousCallback = listeners[name] {
      JSContext.current()!.virtualMachine.removeManagedReference(previousCallback, withOwner: self)
    }
    let managed = JSManagedValue(value: callback)
    listeners[name] = managed
    JSContext.current()!.virtualMachine.addManagedReference(managed, withOwner: self)
  }
}


class JavascriptAPIGlobalChild: JavascriptAPI, JavascriptAPIGlobalChildExportable {
  private var listeners: [String: JSManagedValue] = [:]

  func sendMessage(_ name: String, _ data: JSValue) {

  }

  func onMessage(_ name: String, _ callback: JSValue) {
    if let previousCallback = listeners[name] {
      JSContext.current()!.virtualMachine.removeManagedReference(previousCallback, withOwner: self)
    }
    let managed = JSManagedValue(value: callback)
    listeners[name] = managed
    JSContext.current()!.virtualMachine.addManagedReference(managed, withOwner: self)
  }
}
