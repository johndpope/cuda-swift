//
//  Device.swift
//  CUDA
//
//  Created by Richard Wei on 9/28/16.
//
//

import CCUDA

open class Context : CHandleCarrier {

    public typealias Handle = CUcontext

    let handle: CUcontext

    private static var instances: [CUcontext : Context] = [:]

    deinit {
        Context.instances.removeValue(forKey: handle)
        !!cuCtxDestroy_v2(handle)
    }

    open class var device: Device {
        var deviceHandle: CUdevice = 0
        !!cuCtxGetDevice(&deviceHandle)
        return Device(deviceHandle)
    }

    open class var priorityRange: Range<Int> {
        var lowerBound: Int32 = 0
        var upperBound: Int32 = 0
        !!cuCtxGetStreamPriorityRange(&lowerBound, &upperBound)
        return Int(lowerBound)..<Int(upperBound)
    }

    /// Creates a context object and bind it to the handle.
    /// Will destroy the handle when object's lifetime ends.
    internal init(binding handle: CUcontext) {
        self.handle = handle
    }

    /// Binds the specified CUDA context to the calling CPU thread.
    /// If there exists a CUDA context stack on the calling CPU thread,
    /// this will replace the top of that stack with self.
    open func bindToThread() {
        !!cuCtxPushCurrent_v2(handle)
    }

    /// Pushes the given context ctx onto the CPU thread's stack of current
    /// contexts. The specified context becomes the CPU thread's current
    /// context, so all CUDA functions that operate on the current context 
    /// are affected.
    open func push() {
        !!cuCtxPushCurrent_v2(handle)
    }

    /// Pops the current CUDA context from the CPU thread and returns it
    /// - returns: the popped context, if any
    open class func pop() -> Context? {
        var handle: CUcontext?
        cuCtxPopCurrent_v2(&handle)
        return handle == nil ? nil : instances[handle!]!
    }

    open class func synchronize() throws {
        try ensureSuccess(cuCtxSynchronize())
    }
    
    public func withUnsafeHandle<Result>
        (_ body: (Handle) throws -> Result) rethrows -> Result {
        return try body(handle)
    }

}
