import XCTest
@testable import JsonconverterCore

final class ConverterTests: XCTestCase {
    func testMinifiesWithSortedKeys() throws {
        let out = try JSONConverter.format(#"{ "b": 1, "a": [true, null, "x/y"], "c": 2.5 }"#, pretty: false)
        XCTAssertEqual(out, #"{"a":[true,null,"x/y"],"b":1,"c":2.5}"#)
    }

    func testRejectsInvalidJSON() {
        XCTAssertThrowsError(try JSONConverter.format("{\"a\":", pretty: true))
    }

    func testKeepsBooleansAndNumbersApart() throws {
        XCTAssertEqual(try JSONConverter.parse("[1, true, 0, false]"),
                       .array([.number(1), .bool(true), .number(0), .bool(false)]))
    }

    func testFlattensNestedValues() throws {
        let v = try JSONConverter.parse(#"{"user":{"name":"Book","tags":["a","b"]},"empty":{}}"#)
        let flat = JSONConverter.flatten(v)
        XCTAssertEqual(flat["user.name"], .string("Book"))
        XCTAssertEqual(flat["user.tags.1"], .string("b"))
        XCTAssertEqual(flat["empty"], .object([:]))
    }

    func testJsonToCsvEscapesAndUnionsColumns() throws {
        let csv = try JSONConverter.jsonToCSV(#"[{"name":"A, Inc","n":1},{"name":"Say \"hi\"","extra":true}]"#)
        XCTAssertEqual(csv, "extra,n,name\r\n,1,\"A, Inc\"\r\ntrue,,\"Say \"\"hi\"\"\"")
        XCTAssertThrowsError(try JSONConverter.jsonToCSV(#"{"a":1}"#)) {
            XCTAssertEqual($0 as? ConversionError, .notAnArrayOfObjects)
        }
    }

    func testParsesRfc4180() throws {
        let rows = try CSV.parse("a,b\r\n\"x, y\",\"line1\nline2\"\n\"q\"\"q\",\n")
        XCTAssertEqual(rows, [["a", "b"], ["x, y", "line1\nline2"], ["q\"q", ""]])
        XCTAssertThrowsError(try CSV.parse("\"open"))
    }

    func testCsvToJsonInfersTypesButKeepsCodes() throws {
        let json = try JSONConverter.csvToJSON("id,code,active,score\n1,007,true,2.5\n")
        XCTAssertEqual(json, #"[{"active":true,"code":"007","id":1,"score":2.5}]"#)
        XCTAssertThrowsError(try JSONConverter.csvToJSON("a,b\n1\n"))
        XCTAssertEqual(try JSONConverter.csvToJSON(""), "[]")
    }

    func testRoundTrip() throws {
        let original = #"[{"a":"1","b":"x"}]"#
        let csv = try JSONConverter.jsonToCSV(original)
        XCTAssertEqual(try JSONConverter.csvToJSON(csv, inferTypes: false), original)
    }
}
