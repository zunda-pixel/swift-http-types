//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift HTTP Types open source project
//
// Copyright (c) 2023 Apple Inc. and the Swift HTTP Types project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift HTTP Types project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import HTTPTypes

extension String {
    var isASCII: Bool {
        utf8.allSatisfy { $0 & 0x80 == 0 }
    }
}

extension HTTPField {
    init(name: Name, isoLatin1Value: String) {
        if isoLatin1Value.isASCII {
            self.init(name: name, value: isoLatin1Value)
        } else {
            self = withUnsafeTemporaryAllocation(of: UInt8.self, capacity: isoLatin1Value.unicodeScalars.count) { buffer in
                for (index, scalar) in isoLatin1Value.unicodeScalars.enumerated() {
                    if scalar.value > UInt8.max {
                        buffer.initializeElement(at: index, to: 0x20)
                    } else {
                        buffer.initializeElement(at: index, to: UInt8(truncatingIfNeeded: scalar.value))
                    }
                }
                return HTTPField(name: name, value: buffer)
            }
        }
    }

    var isoLatin1Value: String {
        if value.isASCII {
            return value
        } else {
            return withUnsafeValueBytes { buffer in
                let scalars = buffer.lazy.map { UnicodeScalar(UInt32($0))! }
                var string = ""
                string.unicodeScalars.append(contentsOf: scalars)
                return string
            }
        }
    }
}
