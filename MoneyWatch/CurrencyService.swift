import Foundation

class CurrencyService {
    static let shared = CurrencyService()
    
    // Default conversion rate as fallback
    private let defaultCADRate: Double = 1.4
    
    // Current conversion rate
    private(set) var cadToUsdRate: Double = 1.4
    
    // Last update timestamp
    private var lastUpdateTime: Date?
    
    // Update interval in seconds (10 minutes)
    private let updateInterval: TimeInterval = 600
    
    // API endpoint for currency rates
    private let apiURL = "https://open.er-api.com/v6/latest/USD"
    
    private init() {
        // Immediately fetch rates on initialization
        fetchLatestRates()
    }
    
    /// Fetch latest currency rates from API
    func fetchLatestRates(completion: ((Bool) -> Void)? = nil) {
        // Check if we need to update based on time interval
        if let lastUpdate = lastUpdateTime,
           Date().timeIntervalSince(lastUpdate) < updateInterval {
            completion?(true)
            return
        }
        
        guard let url = URL(string: apiURL) else {
            completion?(false)
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self,
                  let data = data,
                  error == nil,
                  let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                DispatchQueue.main.async {
                    completion?(false)
                }
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let rates = json["rates"] as? [String: Any],
                   let cadRate = rates["CAD"] as? Double {
                    
                    DispatchQueue.main.async {
                        self.cadToUsdRate = cadRate
                        self.lastUpdateTime = Date()
                        print("Updated CAD rate: \(cadRate)")
                        completion?(true)
                    }
                } else {
                    DispatchQueue.main.async {
                        completion?(false)
                    }
                }
            } catch {
                print("Error parsing currency data: \(error)")
                DispatchQueue.main.async {
                    completion?(false)
                }
            }
        }
        
        task.resume()
    }
    
    /// Get current CAD to USD rate (or default if not available)
    func getCurrentCADRate() -> Double {
        return cadToUsdRate
    }
    
    /// Schedule regular updates
    func startRegularUpdates() {
        // Create a timer to update rates every 10 minutes
        Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            self?.fetchLatestRates()
        }
    }
}
