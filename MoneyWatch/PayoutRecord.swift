import Foundation

struct PayoutRecord: Identifiable, Codable, Equatable {
    var id = UUID()
    let amount: Double      // Always stored in USD
    let timestamp: Date
    
    // No longer need currency since everything is in USD
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
    
    // Implementing Equatable
    static func == (lhs: PayoutRecord, rhs: PayoutRecord) -> Bool {
        return lhs.id == rhs.id &&
               lhs.amount == rhs.amount &&
               lhs.timestamp == rhs.timestamp
    }
}
