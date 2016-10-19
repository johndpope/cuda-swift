//
//  Function.swift
//  CUDA
//
//  Created by Richard Wei on 10/16/16.
//
//

import CCUDA

public struct Function {

    let handle: CUfunction

    public enum CachePreference : UInt32 {
        case none = 0x00
        case shared = 0x01
        case L1 = 0x02
        case equal = 0x03
    }

    public var cachePreference: CachePreference = .none {
        didSet {
            cuFuncSetCacheConfig(
                handle, CUfunc_cache(rawValue: cachePreference.rawValue)
            )
        }
    }

    public var sharedMemoryBankSize: SharedMemoryBankSize = .default {
        didSet {
            cuFuncSetSharedMemConfig(
                handle,
                CUsharedconfig(rawValue: sharedMemoryBankSize.rawValue)
            )
        }
    }

    init(handle: CUfunction) {
        self.handle = handle
    }

    /// Grid of blocks
    public struct GridSize {
        let x: Int, y: Int, z: Int
    }

    /// Block of threads
    public struct BlockSize {
        let x: Int, y: Int, z: Int
        /// Shared memory size per thread
        let sharedMemorySize: Int
    }

    public func launch(onArguments arguments: [Any], inGrid gridSize: GridSize,
                       ofBlocks blockSize: BlockSize, stream: Stream?) throws {
        try arguments.withUnsafeBufferPointer { ptr in
            let argPtr = unsafeBitCast(ptr.baseAddress, to: UnsafeMutablePointer<UnsafeMutableRawPointer?>.self)
            try ensureSuccess(
                cuLaunchKernel(handle, UInt32(gridSize.x), UInt32(gridSize.y), UInt32(gridSize.z),
                               UInt32(blockSize.x), UInt32(blockSize.y), UInt32(blockSize.z),
                               UInt32(blockSize.sharedMemorySize), stream?.handle ?? nil, argPtr, nil)
            )
        }
    }

}

public extension Function {

    public var maxThreadsPerBlock: Int {
        var maxThreads: Int32 = 0
        cuFuncGetAttribute(&maxThreads,
                           CU_FUNC_ATTRIBUTE_MAX_THREADS_PER_BLOCK,
                           handle)
        return Int(maxThreads)
    }

    public var sharedSize: Int {
        var maxThreads: Int32 = 0
        cuFuncGetAttribute(&maxThreads,
                           CU_FUNC_ATTRIBUTE_SHARED_SIZE_BYTES,
                           handle)
        return Int(maxThreads)
    }

    public var userConstSize: Int {
        var maxThreads: Int32 = 0
        cuFuncGetAttribute(&maxThreads,
                           CU_FUNC_ATTRIBUTE_CONST_SIZE_BYTES,
                           handle)
        return Int(maxThreads)
    }
    
    public var localSize: Int {
        var maxThreads: Int32 = 0
        cuFuncGetAttribute(&maxThreads,
                           CU_FUNC_ATTRIBUTE_LOCAL_SIZE_BYTES,
                           handle)
        return Int(maxThreads)
    }

    public var registerCount: Int {
        var maxThreads: Int32 = 0
        cuFuncGetAttribute(&maxThreads,
                           CU_FUNC_ATTRIBUTE_NUM_REGS,
                           handle)
        return Int(maxThreads)
    }
    
    public var PTXVersion: Int {
        var maxThreads: Int32 = 0
        cuFuncGetAttribute(&maxThreads,
                           CU_FUNC_ATTRIBUTE_PTX_VERSION,
                           handle)
        return Int(maxThreads)
    }
    
    public var binaryVersion: Int {
        var maxThreads: Int32 = 0
        cuFuncGetAttribute(&maxThreads,
                           CU_FUNC_ATTRIBUTE_BINARY_VERSION,
                           handle)
        return Int(maxThreads)
    }

}