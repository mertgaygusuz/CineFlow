import Foundation

extension String {
    var localized: String {
        NSLocalizedString(self, comment: "")
    }

    func localized(with args: CVarArg...) -> String {
        String(format: localized, arguments: args)
    }
}
