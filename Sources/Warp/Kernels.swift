//
//  Kernels.swift
//  CUDA
//
//  Created by Richard Wei on 11/3/16.
//
//

extension StaticString : Equatable {
    public static func == (lhs: StaticString, rhs: StaticString) -> Bool {
        return lhs.withUTF8Buffer { lBuf in
            rhs.withUTF8Buffer { rBuf in
                lBuf.elementsEqual(rBuf)
            }
        }
    }
}

enum KernelSource: StaticString {
    case sum = "extern \"C\" __global__ void sum(TYPE *vector, long count, TYPE *result) { *result = 0; for (long i = 0; i < count; i++) *result += vector[i]; }"
    case asum = "extern \"C\" __global__ void asum(TYPE *vector, long count, TYPE *result) { *result = 0; for (long i = 0; i < count; i++) *result += abs(vector[i]); }"
}

extension KernelSource : Hashable {
    var hashValue: Int {
        return rawValue.utf8Start.hashValue
    }
}
