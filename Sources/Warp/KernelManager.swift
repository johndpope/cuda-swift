//
//  KernelManager.swift
//  CUDA
//
//  Created by Richard Wei on 11/3/16.
//
//

import struct CUDARuntime.Device
import CUDADriver
import NVRTC

final class KernelManager {

    fileprivate static var instances: [Int : KernelManager] = [:]

    static func global(on device: Device) -> KernelManager {
        if let manager = instances[device.index] {
            return manager
        }
        let manager = KernelManager(device: device)
        instances[device.index] = manager
        return manager
    }

    let device: Device

    fileprivate var modules: [KernelDataType : [KernelSource : Module]] = Dictionary(minimumCapacity: 16)

    init(device: Device) {
        self.device = device
    }

    func launchKernel<T: KernelDataProtocol>(_ source: KernelSource, forType type: T.Type,
                      arguments: [KernelArgument], blockCount: Int, threadCount: Int,
                      memory: Int = 0, stream: Stream? = nil) {
        /// Check and add entry for type T
        let cTypeName = T.kernelDataType
        if !modules.keys.contains(T.kernelDataType) {
            modules[cTypeName] = Dictionary(minimumCapacity: 32)
        }

        device.sync {
            let module: Module
            if let cachedModule = modules[cTypeName]![source] {
                module = cachedModule
            } else {
                /// Compile using NVRTC
                module = try! Module(
                    source: source.rawValue,
                    compileOptions: [
                        .computeCapability(device.computeCapability),
                        .useFastMath,
                        .disableWarnings,
                        .defineMacro("TYPE", as: T.kernelDataType.rawValue)
                    ]
                )
                /// Cache it
                modules[cTypeName]![source] = module
            }
            
            /// Launch function
            let function = module.function(named: String(describing: source))!
            try! function<<<(blockCount, threadCount, memory, stream)>>>(arguments)
        }
    }

}
