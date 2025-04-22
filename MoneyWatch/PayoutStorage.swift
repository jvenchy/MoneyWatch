import Foundation

// Utility class for storing and retrieving payout records
class PayoutStorage {
    static let shared = PayoutStorage()
    
    private let key = "saved_payouts"
    
    private init() {}
    
    func savePayouts(_ payouts: [PayoutRecord]) {
        do {
            let data = try JSONEncoder().encode(payouts)
            UserDefaults.standard.set(data, forKey: key)
        } catch {
            print("Failed to save payouts: \(error)")
        }
    }
    
    func loadPayouts() -> [PayoutRecord] {
        guard let data = UserDefaults.standard.data(forKey: key) else {
            return []
        }
        
        do {
            let payouts = try JSONDecoder().decode([PayoutRecord].self, from: data)
            return payouts
        } catch {
            print("Failed to load payouts: \(error)")
            return []
        }
    }
    
    func clearAllPayouts() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
