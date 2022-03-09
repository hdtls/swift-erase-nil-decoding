//
//  Copyright (c) 2022 Junfeng Zhang
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import XCTest
@testable import EraseNilDecoding

final class EraseNilDecodingTests: XCTestCase {

    struct Outer: Codable, Equatable {
        @EraseNilToTrue var eraseNilToTrue: Bool
        @EraseNilToFalse var eraseNilToFalse: Bool
        @EraseNilToZero var eraseNilToZero: Int
        @EraseNilToEmpty var eraseNilToArray: Array<String>
        @EraseNilToEmpty var eraseNilToString: String
        @EraseNilToEmpty var eraseNilToDictionary: [String : Int]
        @EraseNilToEmpty var eraseNilToInner: Inner
    }
    
    struct Inner: Codable, Equatable, EmptyInitializable {
        var id: Int
        
        init(id: Int) {
            self.id = id
        }
        
        init() {
            self.init(id: .zero)
        }
    }
    
    func testDecodeFieldFromNil() throws {
        let data = try JSONSerialization.data(withJSONObject: [String : Any](), options: .fragmentsAllowed)
        
        let model = try JSONDecoder().decode(Outer.self, from: data)
        
        XCTAssertEqual(model.eraseNilToTrue, true)
        XCTAssertEqual(model.eraseNilToFalse, false)
        XCTAssertEqual(model.eraseNilToZero, 0)
        XCTAssertEqual(model.eraseNilToArray, [])
        XCTAssertEqual(model.eraseNilToString, "")
        XCTAssertEqual(model.eraseNilToDictionary, [:])
        XCTAssertEqual(model.eraseNilToInner, .init())
    }
    
    func testEraseOnlyIfTheFieldValueIsNil() throws {
        let jsonObject: [String : Any] = [
            "eraseNilToTrue": false,
            "eraseNilToFalse": false,
            "eraseNilToZero": 1,
            "eraseNilToArray": [
                "firstObject"
            ],
            "eraseNilToString": "This is string field.",
            "eraseNilToDictionary": [
                "key" : 1
            ],
            "eraseNilToInner": [
                "id": 1
            ]
        ]
        
        let data = try JSONSerialization.data(withJSONObject: jsonObject, options: .fragmentsAllowed)
        
        let model = try JSONDecoder().decode(Outer.self, from: data)

        XCTAssertEqual(model.eraseNilToTrue, false)
        XCTAssertEqual(model.eraseNilToFalse, false)
        XCTAssertEqual(model.eraseNilToZero, 1)
        XCTAssertEqual(model.eraseNilToArray, ["firstObject"])
        XCTAssertEqual(model.eraseNilToString, "This is string field.")
        XCTAssertEqual(model.eraseNilToDictionary, ["key" : 1])
        XCTAssertEqual(model.eraseNilToInner, .init(id: 1))
    }
    
    func testEncoding() throws {
        let expected = try JSONSerialization.data(withJSONObject: [String : Any](), options: .fragmentsAllowed)
        var model = try JSONDecoder().decode(Outer.self, from: expected)
        var jsonData = try JSONEncoder().encode(model)
        XCTAssertEqual(jsonData, expected)
        
        var jsonString = String(data: jsonData, encoding: .utf8)
        XCTAssertNotNil(jsonString)
        XCTAssertFalse(jsonString!.contains("eraseNilToTrue"))
        XCTAssertFalse(jsonString!.contains("eraseNilToFalse"))
        XCTAssertFalse(jsonString!.contains("eraseNilToString"))
        XCTAssertFalse(jsonString!.contains("eraseNilToArray"))
        XCTAssertFalse(jsonString!.contains("eraseNilToDictionary"))
        XCTAssertFalse(jsonString!.contains("eraseNilToInner"))

        model.eraseNilToTrue = true
        jsonData = try JSONEncoder().encode(model)
        jsonString = String(data: jsonData, encoding: .utf8)
        
        XCTAssertNotNil(jsonString)
        XCTAssertTrue(jsonString!.contains("eraseNilToTrue"))
        XCTAssertFalse(jsonString!.contains("eraseNilToFalse"))
        XCTAssertFalse(jsonString!.contains("eraseNilToString"))
        XCTAssertFalse(jsonString!.contains("eraseNilToArray"))
        XCTAssertFalse(jsonString!.contains("eraseNilToDictionary"))
        XCTAssertFalse(jsonString!.contains("eraseNilToInner"))
    }
    
    func testCustomEraseNilDecodableWorks() throws {
        
        struct Two: Codable, EraseNilDecodable {
            static var erasedValue: Int {
                2
            }
        }
        
        struct Model: Codable {
            @EraseNilDecoding<Two> var int: Int
        }
        
        let data = try JSONSerialization.data(withJSONObject: [String : Any](), options: .fragmentsAllowed)
        let result = try JSONDecoder().decode(Model.self, from: data)
        
        XCTAssertEqual(result.int, 2)
    }
}
