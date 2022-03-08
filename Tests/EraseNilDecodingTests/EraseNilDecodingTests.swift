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
        @EraseNilToTrue var isTrue: Bool
        @EraseNilToFalse var isFalse: Bool
        @EraseNilToZero var zero: Int
        @EraseNilToEmpty var array: Array<String>
        @EraseNilToEmpty var string: String
        @EraseNilToEmpty var dictionary: [String : Int]
        @EraseNilToEmpty var inner: Inner
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
        
        do {
            let model = try JSONDecoder().decode(Outer.self, from: data)
            
            XCTAssertEqual(model.isTrue, true)
            XCTAssertEqual(model.isFalse, false)
            XCTAssertEqual(model.zero, 0)
            XCTAssertEqual(model.array, [])
            XCTAssertEqual(model.string, "")
            XCTAssertEqual(model.dictionary, [:])
            XCTAssertEqual(model.inner, .init())
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testEraseOnlyIfTheFieldValueIsNil() throws {
        let jsonObject: [String : Any] = [
            "isTrue": false,
            "isFalse": false,
            "zero": 1,
            "array": [
                "firstObject"
            ],
            "string": "This is string field.",
            "dictionary": [
                "key" : 1
            ],
            "inner": [
                "id": 1
            ]
        ]
        
        let data = try JSONSerialization.data(withJSONObject: jsonObject, options: .fragmentsAllowed)
        do {
            let model = try JSONDecoder().decode(Outer.self, from: data)

            XCTAssertEqual(model.isTrue, false)
            XCTAssertEqual(model.isFalse, false)
            XCTAssertEqual(model.zero, 1)
            XCTAssertEqual(model.array, ["firstObject"])
            XCTAssertEqual(model.string, "This is string field.")
            XCTAssertEqual(model.dictionary, ["key" : 1])
            XCTAssertEqual(model.inner, .init(id: 1))
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testEncoding() throws {
        
        let expected = Outer(isTrue: false, isFalse: true, zero: 1, array: ["firstObject"], string: "test string.", dictionary: ["key" : 1], inner: .init())
        
        let data = try JSONEncoder().encode(expected)
        
        let result = try JSONDecoder().decode(Outer.self, from: data)
        
        XCTAssertEqual(result, expected)
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
