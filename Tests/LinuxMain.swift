import XCTest
@testable import CUDADriverTests
@testable import CUDARuntimeTests
@testable import CuBLASTests
@testable import NVRTCTests

XCTMain([
     testCase(CUDADriverTests.allTests),
     testCase(CUDARuntimeTests.allTests),
     testCase(CuBLASTests.allTests),
     testCase(NVRTCTests.allTests),
])
