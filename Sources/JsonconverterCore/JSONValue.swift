import Foundation

/// A JSON document as a plain Swift value (keeps booleans and numbers apart,
/// which `JSONSerialization` + `NSNumber` does not on Apple platforms).
public indirect enum JSONValue: Equatable, Codable {
    case null
    case bool(Bool)
    case number(Double)
    case string(String)
    case array([JSONValue])
    case object([String: JSONValue])

    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if c.decodeNil() { self = .null }
        else if let b = try? c.decode(Bool.self) { self = .bool(b) }
        else if let n = try? c.decode(Double.self) { self = .number(n) }
        else if let s = try? c.decode(String.self) { self = .string(s) }
        else if let a = try? c.decode([JSONValue].self) { self = .array(a) }
        else if let o = try? c.decode([String: JSONValue].self) { self = .object(o) }
        else { throw DecodingError.dataCorruptedError(in: c, debugDescription: "unsupported JSON value") }
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .null: try c.encodeNil()
        case .bool(let b): try c.encode(b)
        case .number(let n):
            if n.rounded() == n && abs(n) < 1e15 { try c.encode(Int64(n)) } else { try c.encode(n) }
        case .string(let s): try c.encode(s)
        case .array(let a): try c.encode(a)
        case .object(let o): try c.encode(o)
        }
    }

    /// Text used for a CSV cell.
    public var cellText: String {
        switch self {
        case .null: return ""
        case .bool(let b): return b ? "true" : "false"
        case .number(let n): return n.rounded() == n && abs(n) < 1e15 ? String(Int64(n)) : String(n)
        case .string(let s): return s
        case .array, .object:
            let data = (try? JSONConverter.encode(self, pretty: false)) ?? Data()
            return String(decoding: data, as: UTF8.self)
        }
    }
}

public enum ConversionError: Error, Equatable {
    case invalidJSON(String)
    case notAnArrayOfObjects
    case invalidCSV(String)
}

public enum JSONConverter {
    public static func parse(_ text: String) throws -> JSONValue {
        do {
            return try JSONDecoder().decode(JSONValue.self, from: Data(text.utf8))
        } catch {
            throw ConversionError.invalidJSON(String(describing: error))
        }
    }

    public static func encode(_ value: JSONValue, pretty: Bool) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = pretty ? [.sortedKeys, .prettyPrinted, .withoutEscapingSlashes] : [.sortedKeys, .withoutEscapingSlashes]
        return try encoder.encode(value)
    }

    /// Pretty-prints (2-space indent on Apple platforms) or minifies JSON text with sorted keys.
    public static func format(_ text: String, pretty: Bool) throws -> String {
        String(decoding: try encode(parse(text), pretty: pretty), as: UTF8.self)
    }

    /// Flattens nested objects/arrays into dot paths: {"a":{"b":[1]}} → ["a.b.0": 1].
    public static func flatten(_ value: JSONValue, prefix: String = "") -> [String: JSONValue] {
        func join(_ key: String) -> String { prefix.isEmpty ? key : prefix + "." + key }
        switch value {
        case .object(let o) where !o.isEmpty:
            return o.reduce(into: [:]) { acc, kv in acc.merge(flatten(kv.value, prefix: join(kv.key))) { a, _ in a } }
        case .array(let a) where !a.isEmpty:
            return a.enumerated().reduce(into: [:]) { acc, e in acc.merge(flatten(e.element, prefix: join(String(e.offset)))) { a, _ in a } }
        default:
            return [prefix: value]
        }
    }

    /// Converts a JSON array of objects to RFC 4180 CSV. Columns are the sorted
    /// union of flattened keys; missing values become empty cells.
    public static func jsonToCSV(_ text: String) throws -> String {
        guard case .array(let items) = try parse(text) else { throw ConversionError.notAnArrayOfObjects }
        var rows: [[String: JSONValue]] = []
        for item in items {
            guard case .object = item else { throw ConversionError.notAnArrayOfObjects }
            rows.append(flatten(item))
        }
        let headers = Set(rows.flatMap { $0.keys }).sorted()
        var lines = [headers.map(CSV.escape).joined(separator: ",")]
        for row in rows {
            lines.append(headers.map { CSV.escape(row[$0]?.cellText ?? "") }.joined(separator: ","))
        }
        return lines.joined(separator: "\r\n")
    }

    /// Converts CSV with a header row to a JSON array of objects. Cells that look
    /// like numbers or booleans are typed when `inferTypes` is true.
    public static func csvToJSON(_ csv: String, inferTypes: Bool = true, pretty: Bool = false) throws -> String {
        let table = try CSV.parse(csv)
        guard let header = table.first else { return "[]" }
        var objects: [JSONValue] = []
        for (n, row) in table.dropFirst().enumerated() {
            guard row.count == header.count else {
                throw ConversionError.invalidCSV("row \(n + 2) has \(row.count) cells, expected \(header.count)")
            }
            var obj: [String: JSONValue] = [:]
            for (key, cell) in zip(header, row) { obj[key] = inferTypes ? infer(cell) : .string(cell) }
            objects.append(.object(obj))
        }
        return String(decoding: try encode(.array(objects), pretty: pretty), as: UTF8.self)
    }

    static func infer(_ cell: String) -> JSONValue {
        switch cell {
        case "true": return .bool(true)
        case "false": return .bool(false)
        default:
            // Keep leading-zero codes such as "007" or phone numbers as strings.
            let looksNumeric = cell.range(of: #"^-?(0|[1-9][0-9]*)(\.[0-9]+)?$"#, options: .regularExpression) != nil
            if looksNumeric, let d = Double(cell) { return .number(d) }
            return .string(cell)
        }
    }
}

public enum CSV {
    public static func escape(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") || field.contains("\r") {
            return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return field
    }

    /// RFC 4180 parser: quoted fields, doubled quotes, embedded commas and newlines, CRLF or LF.
    public static func parse(_ text: String) throws -> [[String]] {
        var rows: [[String]] = []
        var row: [String] = []
        var field = ""
        var inQuotes = false
        var fieldStarted = false
        var chars = Array(text.unicodeScalars).makeIterator()
        var pending: Unicode.Scalar? = nil
        func next() -> Unicode.Scalar? {
            if let p = pending { pending = nil; return p }
            return chars.next()
        }
        while let ch = next() {
            if inQuotes {
                if ch == "\"" {
                    if let peek = next() {
                        if peek == "\"" { field.unicodeScalars.append("\"") } else { inQuotes = false; pending = peek }
                    } else { inQuotes = false }
                } else {
                    field.unicodeScalars.append(ch)
                }
                continue
            }
            switch ch {
            case "\"" where !fieldStarted:
                inQuotes = true; fieldStarted = true
            case ",":
                row.append(field); field = ""; fieldStarted = false
            case "\r":
                continue
            case "\n":
                row.append(field); rows.append(row); row = []; field = ""; fieldStarted = false
            default:
                field.unicodeScalars.append(ch); fieldStarted = true
            }
        }
        if inQuotes { throw ConversionError.invalidCSV("unterminated quoted field") }
        if fieldStarted || !row.isEmpty { row.append(field); rows.append(row) }
        return rows
    }
}
