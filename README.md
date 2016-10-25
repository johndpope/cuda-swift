# CUDA for Swift

This project provides a native Swift interface to CUDA with the following
features/goals:

* Value types
* Type safety
* Cross-platform
* Real-time compilation
* Operator overloading
* Xcode Playground support

## Components

### Core

- [x] NVRTC - CUDA Runtime Compiler
    - [x] `Compiler`
- [x] CUDADriver - CUDA Driver API
    - [x] `Context`
    - [x] `Device`
    - [x] `Function` (kernel)
    - [x] `PTX`
    - [x] `Module`
    - [x] `Stream`
    - [x] `UnsafeDevicePointer<T>` and `UnsafeMutableDevicePointer<T>`
    - [x] `DriverError` (all error codes from CUDA C API)
- [x] CUDARuntime - CUDA Runtime API
    - [x] `DeviceValue<T>` (generic value in device memory)
    - [x] `DeviceArray<T>` (generic array in device memory)
    - [x] `UnsafeDevicePointer<T>` and `UnsafeMutableDevicePointer<T>`
    - [x] `Device`
    - [x] `Module`, `Function` bridged from `CUDADriver`
    - [x] `Stream`
    - [x] `RuntimeError` (all error codes from CUDA C API)
- [ ] CuBLAS - GPU Basic Linear Algebra Subprograms (in-progress)
    - [x] General functions
    - [x] Level 1 BLAS operations
    - [ ] Level 2 BLAS operations
    - [ ] Level 3 BLAS operations

### Optional

- [x] Swift Playground
  - CUDADriver works in the playground. But other modules cause the "couldn't lookup
    symbols" problem for which we don't have a solution until Xcode is fixed.
  - To use the playground, open the Xcode workspace file, and add a library for
    every modulemap under `Frameworks`.

### Next steps

- [ ] [CuDNN](https://github.com/rxwei/cudnn-swift)

## Quick look

### Value types

CUDA Driver, Runtime, cuBLAS, and NVRTC (real-time compiler) are wrapped in
native Swift types. For higher level APIs such as Runtime and cuBLAS, we wrap
the types that traditionally required unsafe memory allocation into **value
types** with copy-on-write semantics. This enables us to casually perform the
following GPU computation without dealing with manual device memory allocation:

```swift
import CuBLAS

/// Initialize two arrays on device
/// These are the only lines of code that invokes memory copying!
var x: DeviceVector<Float> = [1.0, 2.0, 3.0, 4.0, 5.0]
let y: DeviceVector<Float> = [1.0, 2.0, 3.0, 4.0, 5.0]

/// Scalar multiplication
x *= 2 // x => [2.0, 4.0, 6.0, 8.0, 10.0] stored on device

/// Addition
x += y // x => [3.0, 6.0, 9.0, 12.0, 15.0] stored on device

/// Dot product
x • y // => 165.0 : DeviceValue<Float> stored on device

/// A chain of operations
x *= x • y // x => [495.0, 990.0, 1485.0, 1980.0, 2475.0] stored on device

/// Absolute sum
BLAS.current.sumOfAbsoluteValues(in: x) // => 15 : DeviceValue<Float> stored on device
```

With value types, we can worry less about reference to device memory. The following
example demonstrates copy-on-write.
```swift
let vectorX: DeviceArray<Float> = [1.2, 3.3, -3, 4.0, 5.6, 7.5, -10, -100.2012432, 20]
var vectorY: DeviceArray<Float> = [  1,   2,  3,   4,   5,   6,   7,            8,  9]
/// Make a value reference to vector Y. Right now, this does not copy anything.
let originalVectorY = vectorY
/// Mutate Y by adding vectorX onto vectorY 
vectorY += vectorX
/// Now, vectorY != originalVectorY. Because DeviceArray made a copy upon mutation!
```

### Real-time compilation

In C/C++, we can write all the logic in a *.cu file. How do we do that in Swift? 

Swift Package Manager does not support invoking external build systems, but this is
not a limitation at all! Real-time compilation is convenient and should not be a
performance bottleneck for GPU-heavy applications. We can simply compile *.cu files 
and *.ptx files at runtime using NVRTC. The following code compiles the CUDA kernel
into PTX, and loads it to device memory.

#### Compile source string to PTX
```swift
let source: String =
  + "extern \"C\" __global__ void saxpy(float a, float *x, float *y, float *out, size_t n) {"
  + "    size_t tid = blockIdx.x * blockDim.x + threadIdx.x;"
  + "    if (tid < n) out[tid] = a * x[tid] + y[tid];"
  + "}";
let ptx = try Compiler.compile(Program(source: source))

```
#### Load a module from PTX using Driver API within a context
```swift
Device.main.withContext { context in
    let module = try Module(ptx: ptx)
    let function = module.function(named: "saxpy")
    function.launch(withArguments: ..., inGrid: ..., ofBlocks: ..., stream: ...) 
}
```
#### Alternatively, use Runtime API without dealing with context
```swift
let module = try Module(ptx: ptx)
let function = module.function(named: "saxpy")
function.launch(withArguments: ..., inGrid: ..., ofBlocks: ..., stream: ...) 
```

## Dependencies

- [CCUDA](https://github.com/rxwei/CCUDA)

## Usage

After its initial release, you'll be able to use cuda-swift by adding the
following dependency: 

```swift
.Package(url: "https://github.com/rxwei/cuda-swift", majorVersion: 1)
```

You'll need to specify the path to your CUDA headers and library at `swift build`.

#### macOS
```
swift build -Xcc -I/usr/local/cuda/include -Xlinker -L/usr/local/cuda/lib
```

#### Linux
```
swift build -Xcc -I/usr/lib/cuda/include -Xlinker -L/usr/lib/cuda/lib
```

You may use the Makefile in this project.

## License

MIT License

CUDA is a registered trademark of NVIDIA Corporation.
