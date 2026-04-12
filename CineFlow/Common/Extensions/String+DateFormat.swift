import Foundation

extension String {
    /// "2026-03-15"  →  "15.03.2026"
    var formattedDate: String {
        let input  = DateFormatter()
        input.dateFormat = "yyyy-MM-dd"
        let output = DateFormatter()
        output.dateFormat = "dd.MM.yyyy"
        guard let date = input.date(from: self) else { return self }
        return output.string(from: date)
    }
}
