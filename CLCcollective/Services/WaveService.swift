import Foundation

enum WaveError: Error, Equatable {
    case invalidResponse
    case networkError(Error)
    case authenticationError
    case invalidData
    case businessNotFound
    case emptyResponse
    case graphQLError(String)
    case decodingError(String)
    case noBusinessId
    case serviceNotInitialized
    case noData
    
    var localizedDescription: String {
        switch self {
        case .invalidResponse:
            return "Invalid response from Wave API"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .authenticationError:
            return "Authentication failed - please check your Wave API token"
        case .invalidData:
            return "Invalid data received from Wave API"
        case .businessNotFound:
            return "No business found for this account"
        case .emptyResponse:
            return "Wave API returned an empty response"
        case .graphQLError(let message):
            return "Wave API error: \(message)"
        case .decodingError(let message):
            return "Failed to decode response: \(message)"
        case .noBusinessId:
            return "Business ID not found - please reinitialize the service"
        case .serviceNotInitialized:
            return "Wave service not properly initialized"
        case .noData:
            return "No data received from Wave API"
        }
    }
    
    static func == (lhs: WaveError, rhs: WaveError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidResponse, .invalidResponse),
             (.authenticationError, .authenticationError),
             (.invalidData, .invalidData),
             (.businessNotFound, .businessNotFound),
             (.emptyResponse, .emptyResponse),
             (.noBusinessId, .noBusinessId),
             (.serviceNotInitialized, .serviceNotInitialized),
             (.noData, .noData):
            return true
        case (.networkError(let lhsError), .networkError(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        case (.graphQLError(let lhsMessage), .graphQLError(let rhsMessage)):
            return lhsMessage == rhsMessage
        case (.decodingError(let lhsMessage), .decodingError(let rhsMessage)):
            return lhsMessage == rhsMessage
        default:
            return false
        }
    }
}

class WaveService {
    static let shared = WaveService()
    private let baseURL = "https://gql.waveapps.com/graphql/public"
    
    private var waveToken: String {
        return "HDVxAluwrTYhdQo6O43QO8xgNuzNRz"
    }
    
    private var businessId: String?
    private var businessName: String = "Cochran Films" // Default business
    private var incomeAccountId: String = ""
    private var expenseAccountId: String = ""
    private var isInitialized = false
    private var isInitializing = false
    private var initializationQueue: [(Result<Void, Error>) -> Void] = []
    
    private init() {
        initializeService()
    }
    
    func setBusinessName(_ name: String) {
        if businessName != name {
            businessName = name
            isInitialized = false
            initializeService()
        }
    }
    
    private func initializeService() {
        guard !isInitializing else { return }
        isInitializing = true
        
        print("\nStarting Wave service initialization...")
        print("Initializing for business: \(businessName)")
        fetchBusinessId { [weak self] result in
            switch result {
            case .success(let id):
                self?.businessId = id
                print("Successfully fetched business ID: \(id)")
                self?.fetchAccounts { result in
                    switch result {
                    case .success(let (income, expense)):
                        self?.incomeAccountId = income
                        self?.expenseAccountId = expense
                        print("Successfully fetched account IDs - Income: \(income), Expense: \(expense)")
                        self?.completeInitialization(with: .success(()))
                    case .failure(let error):
                        print("Failed to fetch accounts: \(error.localizedDescription)")
                        self?.completeInitialization(with: .failure(error))
                    }
                }
            case .failure(let error):
                print("Failed to fetch business ID: \(error.localizedDescription)")
                self?.completeInitialization(with: .failure(error))
            }
        }
    }
    
    private func completeInitialization(with result: Result<Void, Error>) {
        switch result {
        case .success:
            isInitialized = true
            print("Wave service initialization completed successfully")
        case .failure(let error):
            isInitialized = false
            print("Wave service initialization failed: \(error.localizedDescription)")
        }
        
        isInitializing = false
        let queue = initializationQueue
        initializationQueue.removeAll()
        
        DispatchQueue.main.async {
            queue.forEach { $0(result) }
        }
    }
    
    private func waitForInitialization(completion: @escaping (Result<Void, Error>) -> Void) {
        if isInitialized {
            completion(.success(()))
            return
        }
        
        initializationQueue.append(completion)
        
        if !isInitializing {
            initializeService()
        }
    }
    
    private func fetchBusinessId(completion: @escaping (Result<String, Error>) -> Void) {
        let query = """
        query {
            businesses {
                edges {
                    node {
                        id
                        name
                        isPersonal
                    }
                }
            }
        }
        """
        
        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        createHeaders().forEach { request.addValue($0.value, forHTTPHeaderField: $0.key) }
        
        let body: [String: Any] = ["query": query]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: body)
            request.httpBody = jsonData
            print("Fetching Business ID - Request JSON: \(String(data: jsonData, encoding: .utf8) ?? "")")
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "WaveService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            // Print response for debugging
            if let responseString = String(data: data, encoding: .utf8) {
                print("Business Query Response: \(responseString)")
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                
                if let errors = json?["errors"] as? [[String: Any]] {
                    let errorMessages = errors.compactMap { $0["message"] as? String }.joined(separator: "\n")
                    throw NSError(domain: "WaveService", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMessages])
                }
                
                guard let data = json?["data"] as? [String: Any],
                      let businesses = data["businesses"] as? [String: Any],
                      let edges = businesses["edges"] as? [[String: Any]] else {
                    throw NSError(domain: "WaveService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not find businesses in response"])
                }
                
                // Find the selected business
                guard let selectedBusiness = edges.first(where: { edge in
                    guard let node = edge["node"] as? [String: Any],
                          let name = node["name"] as? String else { return false }
                    return name == self.businessName
                }), let node = selectedBusiness["node"] as? [String: Any],
                   let businessId = node["id"] as? String else {
                    throw NSError(domain: "WaveService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not find business with name: \(self.businessName)"])
                }
                
                completion(.success(businessId))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    private func fetchAccounts(completion: @escaping (Result<(String, String), Error>) -> Void) {
        let query = """
query FetchBusinessAccounts($businessId: ID!) {
  business(id: $businessId) {
    id
    name
    accounts {
      edges {
        node {
          id
          name
          type {
            name
            value
          }
        }
      }
    }
  }
}
"""
        
        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        createHeaders().forEach { request.addValue($0.value, forHTTPHeaderField: $0.key) }
        
        let body: [String: Any] = [
            "query": query,
            "variables": ["businessId": businessId]
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: body)
            request.httpBody = jsonData
            print("Fetching Accounts - Request JSON: \(String(data: jsonData, encoding: .utf8) ?? "")")
        } catch {
            print("Error serializing accounts request: \(error.localizedDescription)")
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "WaveService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("Accounts Query Response: \(responseString)")
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                
                if let errors = json?["errors"] as? [[String: Any]] {
                    let errorMessages = errors.compactMap { error -> String in
                        let message = error["message"] as? String ?? "Unknown error"
                        let code = (error["extensions"] as? [String: Any])?["code"] as? String ?? "no code"
                        let locations = (error["locations"] as? [[String: Any]])?.map { loc in
                            let line = String(describing: loc["line"] ?? "?")
                            let column = String(describing: loc["column"] ?? "?")
                            return "line: \(line), column: \(column)"
                        }.joined(separator: ", ") ?? "no location"
                        return "[\(code)] \(message) at \(locations)"
                    }.joined(separator: "\n")
                    print("GraphQL Errors: \(errorMessages)")
                    throw WaveError.graphQLError(errorMessages)
                }
                
                guard let data = json?["data"] as? [String: Any],
                      let business = data["business"] as? [String: Any],
                      let accounts = business["accounts"] as? [String: Any],
                      let edges = accounts["edges"] as? [[String: Any]] else {
                    throw NSError(domain: "WaveService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response structure"])
                }
                
                print("\n=== Wave Account Setup ===")
                
                var incomeId: String?
                var expenseId: String?
                
                // Define account names based on business
                let (incomeAccountName, expenseAccountName) = self.businessName == "Course Creator Academy LLC" 
                    ? ("Sales", "Professional Fees")  // Course Creator Academy LLC accounts
                    : ("Sales", "Subcontracted Services")  // Cochran Films accounts
                
                print("\nSearching Accounts...")
                print("Looking for Income Account: \(incomeAccountName)")
                print("Looking for Expense Account: \(expenseAccountName)")
                
                for edge in edges {
                    guard let node = edge["node"] as? [String: Any],
                          let id = node["id"] as? String,
                          let name = node["name"] as? String,
                          let type = node["type"] as? [String: Any],
                          let typeName = type["name"] as? String,
                          let typeValue = type["value"] as? String else { continue }
                    
                    print("\nFound Account:")
                    print("- Name: \(name)")
                    print("- Type: \(typeName)")
                    print("- Value: \(typeValue)")
                    print("- ID: \(id)")
                    
                    if typeValue == "INCOME" && name == incomeAccountName {
                        incomeId = id
                        print("✓ Found \(incomeAccountName) account for income!")
                    } else if typeValue == "EXPENSE" && name == expenseAccountName {
                        expenseId = id
                        print("✓ Found \(expenseAccountName) account for expenses!")
                    }
                }
                
                if incomeId == nil {
                    print("\nAvailable Income Accounts:")
                    edges.compactMap { edge -> String? in
                        guard let node = edge["node"] as? [String: Any],
                              let type = node["type"] as? [String: Any],
                              let typeValue = type["value"] as? String,
                              typeValue == "INCOME",
                              let name = node["name"] as? String else { return nil }
                        return name
                    }.forEach { print("- \($0)") }
                }
                
                if expenseId == nil {
                    print("\nAvailable Expense Accounts:")
                    edges.compactMap { edge -> String? in
                        guard let node = edge["node"] as? [String: Any],
                              let type = node["type"] as? [String: Any],
                              let typeValue = type["value"] as? String,
                              typeValue == "EXPENSE",
                              let name = node["name"] as? String else { return nil }
                        return name
                    }.forEach { print("- \($0)") }
                }
                
                guard let income = incomeId else {
                    throw NSError(domain: "WaveService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not find '\(incomeAccountName)' account. Please make sure it exists in Wave."])
                }
                
                guard let expense = expenseId else {
                    throw NSError(domain: "WaveService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not find '\(expenseAccountName)' account. Please make sure it exists in Wave."])
                }
                
                print("\n✅ Found both required accounts:")
                print("Income: \(incomeAccountName)")
                print("Expense: \(expenseAccountName)")
                completion(.success((income, expense)))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    private func createHeaders() -> [String: String] {
        return [
            "Authorization": "Bearer \(waveToken)",
            "Content-Type": "application/json",
            "Accept": "application/json",
            "X-Requested-With": "XMLHttpRequest"
        ]
    }
    
    private func searchCustomer(email: String) async throws -> String? {
        guard isInitialized else {
            throw WaveError.serviceNotInitialized
        }
        
        guard let businessId = businessId, !businessId.isEmpty else {
            throw WaveError.noBusinessId
        }
        
        let query = """
        {
            business(id: "\(businessId)") {
                id
                customers(page: 1, pageSize: 100) {
                    pageInfo {
                        currentPage
                        totalPages
                        totalCount
                    }
                    edges {
                        node {
                            id
                            name
                            email
                        }
                    }
                }
            }
        }
        """
        
        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        createHeaders().forEach { request.addValue($0.value, forHTTPHeaderField: $0.key) }
        
        let body: [String: Any] = ["query": query]
        
        print("\n=== Searching for Customer ===")
        print("Email: \(email)")
        print("Business ID: \(businessId)")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            if let requestBody = String(data: request.httpBody!, encoding: .utf8) {
                print("Request Body: \(requestBody)")
            }
        } catch {
            print("Failed to serialize request body: \(error)")
            throw WaveError.invalidData
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw WaveError.invalidResponse
        }
        
        print("Response Status Code: \(httpResponse.statusCode)")
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("Response Data: \(responseString)")
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            switch httpResponse.statusCode {
            case 401:
                throw WaveError.authenticationError
            default:
                throw WaveError.graphQLError("HTTP Status: \(httpResponse.statusCode)")
            }
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw WaveError.invalidData
        }
        
        if let errors = json["errors"] as? [[String: Any]] {
            let errorMessages = errors.compactMap { error -> String in
                let message = error["message"] as? String ?? "Unknown error"
                let code = (error["extensions"] as? [String: Any])?["code"] as? String ?? "no code"
                let locations = (error["locations"] as? [[String: Any]])?.map { loc in
                    let line = String(describing: loc["line"] ?? "?")
                    let column = String(describing: loc["column"] ?? "?")
                    return "line: \(line), column: \(column)"
                }.joined(separator: ", ") ?? "no location"
                return "[\(code)] \(message) at \(locations)"
            }.joined(separator: "\n")
            print("GraphQL Errors: \(errorMessages)")
            throw WaveError.graphQLError(errorMessages)
        }
        
        guard let data = json["data"] as? [String: Any],
              let business = data["business"] as? [String: Any],
              let customers = business["customers"] as? [String: Any],
              let edges = customers["edges"] as? [[String: Any]] else {
            print("Invalid response structure")
            throw WaveError.invalidData
        }
        
        // Search for customer with matching email
        for edge in edges {
            if let node = edge["node"] as? [String: Any],
               let customerEmail = node["email"] as? String,
               let customerId = node["id"] as? String,
               customerEmail.lowercased() == email.lowercased() {
                print("✓ Found existing customer with ID: \(customerId)")
                return customerId
            }
        }
        
        print("No existing customer found with email: \(email)")
        return nil
    }
    
    func getOrCreateCustomer(name: String, email: String) async throws -> String {
        print("Checking for existing customer with email: \(email)")
        
        if let existingCustomerId = try await searchCustomer(email: email) {
            print("Using existing customer with ID: \(existingCustomerId)")
            return existingCustomerId
        }
        
        print("No existing customer found, creating new customer...")
        
        return try await withCheckedThrowingContinuation { continuation in
            createCustomer(name: name, email: email) { result in
                switch result {
                case .success(let customerId):
                    print("Successfully created new customer with ID: \(customerId)")
                    continuation.resume(returning: customerId)
                case .failure(let error):
                    print("Failed to create customer: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func createInvoice(
        clientName: String,
        clientEmail: String,
        amount: Double,
        serviceDescription: String,
        invoiceTitle: String,
        dueDate: Date,
        notes: String,
        quantity: Int,
        completion: @escaping (Result<(String, String), Error>) -> Void
    ) {
        Task {
            do {
                // Wait for service initialization first
                try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                    waitForInitialization { result in
                        switch result {
                        case .success:
                            continuation.resume()
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        }
                    }
                }
                
                // Get customer ID once
                let customerId = try await getOrCreateCustomer(name: clientName, email: clientEmail)
                print("✓ Customer ready with ID: \(customerId)")
                
                // Transform the title based on business
                let transformedTitle = businessName == "Course Creator Academy LLC" ? "CCA Education" : invoiceTitle
                
                // Create invoice with customer
                createInvoiceWithCustomer(
                    customerId: customerId,
                    amount: amount,
                    serviceDescription: serviceDescription,
                    invoiceTitle: transformedTitle,
                    dueDate: dueDate,
                    notes: notes,
                    quantity: quantity,
                    completion: completion
                )
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    private func createInvoiceWithCustomer(
        customerId: String,
        amount: Double,
        serviceDescription: String,
        invoiceTitle: String,
        dueDate: Date,
        notes: String,
        quantity: Int,
        completion: @escaping (Result<(String, String), Error>) -> Void
    ) {
        print("\nStep 4: Creating Product...")
        createProduct(
            name: invoiceTitle.isEmpty ? "Video Service" : invoiceTitle,
            description: serviceDescription,
            unitPrice: amount
        ) { [weak self] result in
            switch result {
            case .success(let productId):
                print("✓ Product created successfully with ID: \(productId)")
                print("\nStep 5: Creating Invoice with Product...")
                self?.createInvoiceWithProduct(
                    customerId: customerId,
                    productId: productId,
                    quantity: quantity,
                    dueDate: dueDate,
                    notes: notes,
                    amount: amount,
                    title: invoiceTitle,
                    completion: { result in
                        switch result {
                        case .success(let response):
                            print("\n✅ Invoice Creation Complete!")
                            print("View URL: \(response.0)")
                            print("Invoice ID: \(response.1)")
                            
                            // Return the URL and ID
                            DispatchQueue.main.async {
                                completion(.success(response))
                            }
                            
                        case .failure(let error):
                            print("\n❌ Invoice Creation Failed!")
                            print("Error: \(error.localizedDescription)")
                            DispatchQueue.main.async {
                                completion(.failure(error))
                            }
                        }
                    }
                )
            case .failure(let error):
                print("\n❌ Product Creation Failed!")
                print("Error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    private func createInvoiceWithProduct(
        customerId: String,
        productId: String,
        quantity: Int,
        dueDate: Date,
        notes: String,
        amount: Double,
        title: String = "Video Production Services",
        completion: @escaping (Result<(String, String), Error>) -> Void
    ) {
        guard let businessId = businessId, !businessId.isEmpty else {
            completion(.failure(WaveError.noBusinessId))
            return
        }
        
        print("Creating invoice with Customer ID: \(customerId) and Product ID: \(productId)")
        
        let mutation = """
        mutation CreateInvoice($input: InvoiceCreateInput!) {
            invoiceCreate(input: $input) {
                didSucceed
                inputErrors {
                    message
                    code
                    path
                }
                invoice {
                    id
                    viewUrl
                    status
                    customer {
                        id
                        name
                    }
                    items {
                        product {
                            id
                            name
                        }
                        quantity
                        unitPrice
                        total {
                            value
                        }
                    }
                }
            }
        }
        """
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let invoiceItems: [[String: Any]] = [
            [
                "productId": productId,
                "quantity": quantity,
                "unitPrice": String(format: "%.2f", amount)
            ]
        ]
        
        let invoiceInput: [String: Any] = [
            "businessId": businessId,
            "customerId": customerId,
            "currency": "USD",
            "items": invoiceItems,
            "status": "SAVED",
            "dueDate": dateFormatter.string(from: dueDate),
            "memo": notes,
            "title": title
        ]
        
        let variables: [String: Any] = ["input": invoiceInput]
        
        print("Invoice variables: \(String(describing: variables))")
        
        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(waveToken)", forHTTPHeaderField: "Authorization")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: ["query": mutation, "variables": variables])
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Network error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("Invoice Response Status Code: \(httpResponse.statusCode)")
                print("Response Headers: \(httpResponse.allHeaderFields)")
                
                if httpResponse.statusCode == 401 {
                    print("Authentication error - token may need to be refreshed")
                    DispatchQueue.main.async {
                        completion(.failure(NSError(domain: "WaveService", code: 401, userInfo: [NSLocalizedDescriptionKey: "Authentication failed - please check your Wave API token"])))
                    }
                    return
                }
            }
            
            guard let data = data else {
                let error = NSError(domain: "WaveService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])
                print("No data received in response")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("Invoice Response: \(responseString)")
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                
                if let errors = json?["errors"] as? [[String: Any]] {
                    let errorMessages = errors.compactMap { error -> String in
                        let message = error["message"] as? String ?? "Unknown error"
                        let code = (error["extensions"] as? [String: Any])?["code"] as? String ?? "no code"
                        return "[\(code)] \(message)"
                    }.joined(separator: "\n")
                    print("GraphQL Errors: \(errorMessages)")
                    throw NSError(domain: "WaveService", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMessages])
                }
                
                guard let data = json?["data"] as? [String: Any],
                      let invoiceCreate = data["invoiceCreate"] as? [String: Any] else {
                    print("Invalid response structure: missing data or invoiceCreate")
                    throw NSError(domain: "WaveService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response structure"])
                }
                
                if let inputErrors = invoiceCreate["inputErrors"] as? [[String: Any]],
                   !inputErrors.isEmpty {
                    let errorMessages = inputErrors.compactMap { error -> String in
                        let message = error["message"] as? String ?? "Unknown error"
                        let code = error["code"] as? String ?? "no code"
                        let path = (error["path"] as? [String])?.joined(separator: ".") ?? "no path"
                        return "[\(code)] \(message) at path: \(path)"
                    }.joined(separator: "\n")
                    print("Input Errors: \(errorMessages)")
                    throw WaveError.graphQLError(errorMessages)
                }
                
                guard let didSucceed = invoiceCreate["didSucceed"] as? Bool,
                      didSucceed else {
                    print("Operation did not succeed")
                    throw NSError(domain: "WaveService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invoice creation failed"])
                }
                
                guard let invoice = invoiceCreate["invoice"] as? [String: Any],
                      let viewUrl = invoice["viewUrl"] as? String,
                      let invoiceId = invoice["id"] as? String else {
                    print("Missing invoice, viewUrl, or id in response")
                    throw NSError(domain: "WaveService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid invoice data in response"])
                }
                
                print("\nInvoice created successfully:")
                print("- ID: \(invoiceId)")
                print("- View URL: \(viewUrl)")
                if let customer = invoice["customer"] as? [String: Any] {
                    print("- Customer: \(customer["name"] as? String ?? "Unknown")")
                }
                if let items = invoice["items"] as? [[String: Any]],
                   let firstItem = items.first,
                   let total = firstItem["total"] as? [String: Any],
                   let amount = total["value"] as? String {
                    print("- Total: $\(amount) USD")
                }
                
                DispatchQueue.main.async {
                    completion(.success((viewUrl, invoiceId)))
                }
            } catch {
                print("Error parsing invoice response: \(error)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }.resume()
    }
    
    // Helper method to create a customer in Wave
    func createCustomer(
        name: String,
        email: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard let businessId = businessId, !businessId.isEmpty else {
            completion(.failure(WaveError.noBusinessId))
            return
        }
        
        let mutation = """
        mutation CreateCustomer($input: CustomerCreateInput!) {
            customerCreate(input: $input) {
                didSucceed
                inputErrors {
                    code
                    message
                    path
                }
                customer {
                    id
                    name
                    email
                    currency {
                        code
                    }
                }
            }
        }
        """
        
        // Use provided name or email as fallback for name
        let customerName = name.isEmpty ? email.components(separatedBy: "@").first ?? email : name
        
        let variables: [String: Any] = [
            "input": [
                "businessId": businessId,
                "name": customerName,  // Use the customer name here
                "firstName": "",  // These can remain empty as we're using full name
                "lastName": nil,
                "email": email,
                "currency": "USD"
            ]
        ]
        
        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        createHeaders().forEach { request.addValue($0.value, forHTTPHeaderField: $0.key) }
        
        let body: [String: Any] = [
            "query": mutation,
            "variables": variables
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: body)
            request.httpBody = jsonData
            print("Customer Creation Request JSON: \(String(data: jsonData, encoding: .utf8) ?? "")")
        } catch {
            print("Error serializing customer request: \(error.localizedDescription)")
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Customer creation network error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("Customer Creation Status Code: \(httpResponse.statusCode)")
                print("Response Headers: \(httpResponse.allHeaderFields)")
                
                if httpResponse.statusCode == 401 {
                    print("Authentication error - token may need to be refreshed")
                    DispatchQueue.main.async {
                        completion(.failure(NSError(domain: "WaveService", code: 401, userInfo: [NSLocalizedDescriptionKey: "Authentication failed - token may need to be refreshed"])))
                    }
                    return
                }
            }
            
            guard let data = data else {
                let error = NSError(domain: "WaveService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])
                print("No data received in customer creation response")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("Customer Creation Response: \(responseString)")
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                
                if let errors = json?["errors"] as? [[String: Any]] {
                    let errorMessages = errors.compactMap { error -> String in
                        let message = error["message"] as? String ?? "Unknown error"
                        let code = (error["extensions"] as? [String: Any])?["code"] as? String ?? "no code"
                        let locations = (error["locations"] as? [[String: Any]])?.map { loc in
                            let line = String(describing: loc["line"] ?? "?")
                            let column = String(describing: loc["column"] ?? "?")
                            return "line: \(line), column: \(column)"
                        }.joined(separator: ", ") ?? "no location"
                        return "[\(code)] \(message) at \(locations)"
                    }.joined(separator: "\n")
                    print("GraphQL Errors: \(errorMessages)")
                    throw WaveError.graphQLError(String(describing: errorMessages))
                }
                
                guard let data = json?["data"] as? [String: Any],
                      let customerCreate = data["customerCreate"] as? [String: Any] else {
                    throw WaveError.invalidData
                }
                
                if let inputErrors = customerCreate["inputErrors"] as? [[String: Any]],
                   !inputErrors.isEmpty {
                    let errorMessages = inputErrors.compactMap { error -> String in
                        guard let message = error["message"] as? String else {
                            return "Unknown error"
                        }
                        let code = error["code"] as? String ?? "no code"
                        let path = (error["path"] as? [String])?.joined(separator: ".") ?? "no path"
                        return "[\(code)] \(message) at path: \(path)"
                    }.joined(separator: "\n")
                    print("Input Errors: \(errorMessages)")
                    throw WaveError.graphQLError(errorMessages)
                }
                
                guard let didSucceed = customerCreate["didSucceed"] as? Bool,
                      didSucceed else {
                    throw WaveError.invalidData
                }
                
                guard let customer = customerCreate["customer"] as? [String: Any],
                      let customerId = customer["id"] as? String else {
                    throw WaveError.invalidData
                }
                
                print("Successfully created customer with ID: \(customerId)")
                DispatchQueue.main.async {
                    completion(.success(customerId))
                }
            } catch {
                print("Error parsing customer response: \(error)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }.resume()
    }
    
    private func createProduct(
        name: String,
        description: String,
        unitPrice: Double,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        print("Creating product with name: \(name), price: \(unitPrice)")
        print("Using income account: \(incomeAccountId)")
        print("Using expense account: \(expenseAccountId)")
        
        let productMutation = """
        mutation CreateProduct($input: ProductCreateInput!) {
            productCreate(input: $input) {
                didSucceed
                inputErrors {
                    message
                    code
                    path
                }
                product {
                    id
                    name
                    description
                    unitPrice
                }
            }
        }
        """
        
        guard let businessId = businessId, !businessId.isEmpty else {
            completion(.failure(WaveError.noBusinessId))
            return
        }
        
        let variables: [String: Any] = [
            "input": [
                "businessId": businessId,
                "name": name,
                "description": description,
                "unitPrice": String(format: "%.2f", unitPrice),
                "incomeAccountId": incomeAccountId,
                "expenseAccountId": expenseAccountId
            ]
        ]
        
        print("Product variables: \(variables)")
        
        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        createHeaders().forEach { request.addValue($0.value, forHTTPHeaderField: $0.key) }
        
        let body: [String: Any] = [
            "query": productMutation,
            "variables": variables
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: body)
            request.httpBody = jsonData
            if let requestBody = String(data: jsonData, encoding: .utf8) {
                print("Product Creation Request JSON: \(requestBody)")
            }
        } catch {
            print("Error serializing product request: \(error)")
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Network error in product creation: \(error)")
                completion(.failure(error))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("Product Creation Status Code: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode == 401 {
                    print("Authentication error in product creation - token may need to be refreshed")
                    completion(.failure(NSError(domain: "WaveService", code: 401, userInfo: [NSLocalizedDescriptionKey: "Authentication failed - please check your Wave API token"])))
                    return
                }
            }
            
            guard let data = data else {
                print("No data received in product creation response")
                completion(.failure(NSError(domain: "WaveService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("Product Creation Response: \(responseString)")
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                
                if let errors = json?["errors"] as? [[String: Any]] {
                    let errorMessages = errors.compactMap { error -> String in
                        guard let message = error["message"] as? String else {
                            return "Unknown error"
                        }
                        let extensions = error["extensions"] as? [String: Any]
                        let code = extensions?["code"] as? String ?? "no code"
                        return "[\(code)] \(message)"
                    }.joined(separator: "\n")
                    print("GraphQL Errors in product creation: \(errorMessages)")
                    throw WaveError.graphQLError(errorMessages)
                }
                
                guard let data = json?["data"] as? [String: Any],
                      let productCreate = data["productCreate"] as? [String: Any] else {
                    throw WaveError.invalidData
                }
                
                if let inputErrors = productCreate["inputErrors"] as? [[String: Any]],
                   !inputErrors.isEmpty {
                    let errorMessages = inputErrors.compactMap { error -> String in
                        guard let message = error["message"] as? String else {
                            return "Unknown error"
                        }
                        let code = error["code"] as? String ?? "no code"
                        let path = (error["path"] as? [String])?.joined(separator: ".") ?? "no path"
                        return "[\(code)] \(message) at path: \(path)"
                    }.joined(separator: "\n")
                    print("Input Errors in product creation: \(errorMessages)")
                    throw WaveError.graphQLError(errorMessages)
                }
                
                guard let didSucceed = productCreate["didSucceed"] as? Bool,
                      didSucceed else {
                    throw WaveError.invalidData
                }
                
                guard let product = productCreate["product"] as? [String: Any],
                      let productId = product["id"] as? String else {
                    throw WaveError.invalidData
                }
                
                print("Successfully created product with ID: \(productId)")
                completion(.success(productId))
            } catch {
                print("Error parsing product response: \(error)")
                completion(.failure(error))
            }
        }.resume()
    }
    
    func fetchInvoices(forUserEmail userEmail: String? = nil) async throws -> [Invoice] {
        var allInvoices: [Invoice] = []
        
        // List of businesses to fetch from
        let businesses = ["Cochran Films", "Course Creator Academy LLC"]
        
        for business in businesses {
            print("\n=== Fetching Invoices for \(business) ===")
            if let userEmail = userEmail {
                print("Filtering for user email: \(userEmail)")
            }
            
            // Set the business and reinitialize the service
            setBusinessName(business)
            
            // Wait for initialization with explicit type annotation and error handling
            do {
                try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                    self.waitForInitialization { result in
                        switch result {
                        case .success:
                            print("✓ Successfully initialized for \(business)")
                            continuation.resume()
                        case .failure(let error):
                            print("❌ Failed to initialize for \(business): \(error.localizedDescription)")
                            continuation.resume(throwing: error)
                        }
                    }
                }
                
                guard let businessId = businessId, !businessId.isEmpty else {
                    print("❌ No business ID found for \(business), skipping...")
                    continue
                }
                
                print("✓ Using business ID: \(businessId)")
                
                var currentPage = 1
                var hasMorePages = true
                
                while hasMorePages {
                    let query = """
                    {
                        business(id: "\(businessId)") {
                            invoices(page: \(currentPage), pageSize: 100) {
                                pageInfo {
                                    currentPage
                                    totalPages
                                    totalCount
                                }
                                edges {
                                    node {
                                        id
                                        title
                                        viewUrl
                                        createdAt
                                        modifiedAt
                                        dueDate
                                        amountDue {
                                            value
                                            currency {
                                                code
                                            }
                                        }
                                        status
                                        customer {
                                            id
                                            name
                                            email
                                        }
                                        memo
                                        footer
                                        lastSentAt
                                        lastViewedAt
                                        lastSentVia
                                        items {
                                            product {
                                                name
                                                description
                                            }
                                            quantity
                                            unitPrice
                                            subtotal {
                                                value
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    """
                    
                    let request = createRequest(query: query)
                    print("Fetching page \(currentPage)...")
                    
                    let (data, response) = try await URLSession.shared.data(for: request)
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        throw WaveError.invalidResponse
                    }
                    
                    if httpResponse.statusCode == 401 {
                        throw WaveError.authenticationError
                    }
                    
                    guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                        print("❌ Failed to parse JSON response for \(business)")
                        throw WaveError.invalidData
                    }
                    
                    // Check for GraphQL errors first
                    if let errors = json["errors"] as? [[String: Any]] {
                        let errorMessages = errors.compactMap { error -> String in
                            let message = error["message"] as? String ?? "Unknown error"
                            let code = (error["extensions"] as? [String: Any])?["code"] as? String ?? "no code"
                            return "[\(code)] \(message)"
                        }.joined(separator: "\n")
                        print("GraphQL Errors: \(errorMessages)")
                        throw WaveError.graphQLError(errorMessages)
                    }
                    
                    guard let data = json["data"] as? [String: Any],
                          let business = data["business"] as? [String: Any],
                          let invoices = business["invoices"] as? [String: Any] else {
                        print("❌ Invalid data structure received for \(business)")
                        throw WaveError.invalidData
                    }
                    
                    // Handle case where there are no invoices
                    guard let edges = invoices["edges"] as? [[String: Any]] else {
                        print("ℹ️ No invoices found for \(business)")
                        hasMorePages = false
                        continue
                    }
                    
                    let pageInfo = invoices["pageInfo"] as? [String: Any]
                    let totalPages = pageInfo?["totalPages"] as? Int ?? 1
                    hasMorePages = currentPage < totalPages
                    currentPage += 1
                    
                    if edges.isEmpty {
                        print("ℹ️ No invoices found on page \(currentPage - 1) for \(business)")
                        continue
                    }
                    
                    print("Processing \(edges.count) invoices from page \(currentPage - 1) of \(totalPages)...")
                    
                    // Process invoices for this page
                    for edge in edges {
                        guard let node = edge["node"] as? [String: Any] else { continue }
                        
                        let id = node["id"] as? String ?? ""
                        let title = node["title"] as? String ?? "Untitled Invoice"
                        let viewUrl = node["viewUrl"] as? String ?? ""
                        let createdAtString = node["createdAt"] as? String ?? ""
                        let status = node["status"] as? String ?? "DRAFT"
                        let customer = node["customer"] as? [String: Any] ?? [:]
                        let customerName = customer["name"] as? String ?? "Unknown Customer"
                        let customerEmail = customer["email"] as? String ?? ""
                        let memo = node["memo"] as? String
                        let footer = node["footer"] as? String
                        let lastSentAt = node["lastSentAt"] as? String
                        let lastViewedAt = node["lastViewedAt"] as? String
                        let lastSentVia = node["lastSentVia"] as? String
                        let items = node["items"] as? [[String: Any]] ?? []
                        
                        // Skip if we're filtering by email and this invoice doesn't match
                        if let filterEmail = userEmail?.lowercased(),
                           customerEmail.lowercased() != filterEmail {
                            continue
                        }
                        
                        let amountDue = node["amountDue"] as? [String: Any]
                        print("DEBUG: Raw amountDue: \(String(describing: amountDue))")
                        
                        let amount: Double
                        if let amountValue = amountDue?["value"] {
                            print("DEBUG: Raw amount value: \(String(describing: amountValue)) of type: \(type(of: amountValue))")
                            let stringValue = String(describing: amountValue).replacingOccurrences(of: ",", with: "")
                            if let parsedValue = Double(stringValue) {
                                amount = parsedValue
                                print("DEBUG: Successfully parsed amount: \(amount) from string: \(stringValue)")
                            } else if let numberValue = amountValue as? NSNumber {
                                amount = numberValue.doubleValue
                                print("DEBUG: Successfully parsed amount: \(amount) from NSNumber")
                            } else {
                                print("⚠️ Warning: Could not parse amount value: \(String(describing: amountValue))")
                                amount = 0.0
                            }
                        } else {
                            print("⚠️ Warning: No amount value found in amountDue")
                            amount = 0.0
                        }
                        
                        print("DEBUG: Final parsed amount: \(amount)")
                        
                        let currency = ((amountDue?["currency"] as? [String: Any])?["code"] as? String) ?? "USD"
                        
                        let dateFormatter = ISO8601DateFormatter()
                        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                        
                        let createdAt = dateFormatter.date(from: createdAtString) ?? Date()
                        var dueDate: Date? = nil
                        if let dueDateString = node["dueDate"] as? String {
                            dueDate = dateFormatter.date(from: dueDateString)
                        }
                        
                        // Parse other date fields
                        var lastSentDate: Date? = nil
                        if let lastSentString = lastSentAt {
                            lastSentDate = dateFormatter.date(from: lastSentString)
                        }
                        
                        var lastViewedDate: Date? = nil
                        if let lastViewedString = lastViewedAt {
                            lastViewedDate = dateFormatter.date(from: lastViewedString)
                        }
                        
                        // Convert items to Invoice.LineItems
                        let lineItems = items.compactMap { item -> Invoice.LineItem? in
                            guard let product = item["product"] as? [String: Any],
                                  let name = product["name"] as? String else { return nil }
                            
                            let quantity = item["quantity"] as? Int ?? 1
                            let unitPrice = (item["unitPrice"] as? NSNumber)?.doubleValue ?? 0.0
                            let subtotal = ((item["subtotal"] as? [String: Any])?["value"] as? NSNumber)?.doubleValue ?? 0.0
                            
                            return Invoice.LineItem(
                                productName: name,
                                quantity: quantity,
                                unitPrice: unitPrice,
                                total: subtotal
                            )
                        }
                        
                        let invoice = Invoice(
                            id: id,
                            title: title,
                            viewUrl: viewUrl,
                            createdAt: createdAt,
                            amount: amount,
                            status: status,
                            customerName: customerName,
                            customerEmail: customerEmail,
                            dueDate: dueDate,
                            customerId: customer["id"] as? String ?? "",
                            currency: currency,
                            memo: memo,
                            footer: footer,
                            lastSentAt: lastSentDate,
                            lastViewedAt: lastViewedDate,
                            lastSentVia: lastSentVia,
                            items: lineItems
                        )
                        allInvoices.append(invoice)
                        print("✓ Successfully parsed invoice: \(id) for \(customerEmail)")
                    }
                }
            } catch {
                print("❌ Error processing \(business): \(error.localizedDescription)")
                if let waveError = error as? WaveError, waveError == .businessNotFound {
                    print("⚠️ Skipping \(business) as it was not found in Wave")
                    continue
                }
                // Continue to next business instead of failing completely
                continue
            }
        }
        
        let filteredCount = allInvoices.count
        print("\n✅ Successfully fetched and parsed \(filteredCount) invoice(s) from all businesses")
        if let userEmail = userEmail {
            print("Filtered for user: \(userEmail)")
        }
        
        // Sort invoices by creation date, newest first
        return allInvoices.sorted { $0.createdAt > $1.createdAt }
    }
    
    func deleteInvoice(invoiceId: String) async throws {
        guard isInitialized else {
            throw WaveError.serviceNotInitialized
        }
        
        let mutation = """
        mutation DeleteInvoice($input: InvoiceDeleteInput!) {
            invoiceDelete(input: $input) {
                didSucceed
                inputErrors {
                    message
                    code
                    path
                }
            }
        }
        """
        
        let variables: [String: Any] = [
            "input": [
                "invoiceId": invoiceId
            ]
        ]
        
        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        createHeaders().forEach { request.addValue($0.value, forHTTPHeaderField: $0.key) }
        
        let body: [String: Any] = [
            "query": mutation,
            "variables": variables
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: body)
            request.httpBody = jsonData
            print("Delete Invoice Request: \(String(data: jsonData, encoding: .utf8) ?? "")")
        } catch {
            print("Error serializing delete request: \(error)")
            throw WaveError.invalidData
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("Delete Response Status Code: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode == 401 {
                throw WaveError.authenticationError
            }
            
            if httpResponse.statusCode != 200 {
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Error Response: \(responseString)")
                }
                throw WaveError.graphQLError("HTTP Status: \(httpResponse.statusCode)")
            }
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw WaveError.invalidData
        }
        
        print("Delete Response: \(json)")
        
        if let errors = json["errors"] as? [[String: Any]] {
            let errorMessages = errors.compactMap { error -> String in
                let message = error["message"] as? String ?? "Unknown error"
                let code = (error["extensions"] as? [String: Any])?["code"] as? String ?? "no code"
                return "[\(code)] \(message)"
            }.joined(separator: "\n")
            throw WaveError.graphQLError(errorMessages)
        }
        
        guard let data = json["data"] as? [String: Any],
              let deleteInvoice = data["invoiceDelete"] as? [String: Any] else {
            throw WaveError.invalidData
        }
        
        // Check for input errors
        if let inputErrors = deleteInvoice["inputErrors"] as? [[String: Any]], !inputErrors.isEmpty {
            let errorMessages = inputErrors.compactMap { error -> String in
                let message = error["message"] as? String ?? "Unknown error"
                let code = error["code"] as? String ?? "no code"
                let path = (error["path"] as? [String])?.joined(separator: ".") ?? "no path"
                return "[\(code)] \(message) at path: \(path)"
            }.joined(separator: "\n")
            throw WaveError.graphQLError(errorMessages)
        }
        
        guard let didSucceed = deleteInvoice["didSucceed"] as? Bool, didSucceed else {
            throw WaveError.graphQLError("Failed to delete invoice")
        }
        
        // Successfully deleted
        return
    }
    
    private func makeGraphQLRequest(query: String) async throws -> [String: Any] {
        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        createHeaders().forEach { request.addValue($0.value, forHTTPHeaderField: $0.key) }
        
        let body: [String: Any] = ["query": query]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw WaveError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            switch httpResponse.statusCode {
            case 401:
                throw WaveError.authenticationError
            default:
                throw WaveError.graphQLError("HTTP Status: \(httpResponse.statusCode)")
            }
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw WaveError.invalidData
        }
        
        if let errors = json["errors"] as? [[String: Any]] {
            let errorMessages = errors.compactMap { error -> String? in
                guard let message = error["message"] as? String,
                      let extensions = error["extensions"] as? [String: Any],
                      let code = extensions["code"] as? String else {
                    return "Unknown error"
                }
                return "[\(code)] \(message)"
            }.joined(separator: "\n")
            throw WaveError.graphQLError(errorMessages)
        }
        
        return json
    }
    
    func createInvoiceWithItems(
        clientName: String,
        clientEmail: String,
        items: [(title: String, description: String, amount: Double, quantity: Int)],
        dueDate: Date,
        notes: String,
        completion: @escaping (Result<(String, String), Error>) -> Void
    ) {
        Task {
            do {
                // Wait for service initialization first
                try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                    waitForInitialization { result in
                        switch result {
                        case .success:
                            continuation.resume()
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        }
                    }
                }
                
                // Get customer ID once
                let customerId = try await getOrCreateCustomer(name: clientName, email: clientEmail)
                print("✓ Customer ready with ID: \(customerId)")
                
                // Transform the title based on business
                let transformedTitle = businessName == "Course Creator Academy LLC" ? "CCA Education" : items[0].title
                
                // Create products and invoice
                print("\nStep 2: Creating products...")
                var productIds: [(productId: String, quantity: Int, amount: Double)] = []
                for item in items {
                    let productId = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
                        createProduct(
                            name: item.title,
                            description: item.description,
                            unitPrice: item.amount
                        ) { result in
                            switch result {
                            case .success(let id):
                                continuation.resume(returning: id)
                            case .failure(let error):
                                continuation.resume(throwing: error)
                            }
                        }
                    }
                    productIds.append((productId: productId, quantity: item.quantity, amount: item.amount))
                }
                
                // Create invoice with products
                createInvoiceWithMultipleProducts(
                    customerId: customerId,
                    products: productIds,
                    dueDate: dueDate,
                    notes: notes,
                    title: transformedTitle,
                    completion: completion
                )
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    private func createInvoiceWithMultipleProducts(
        customerId: String,
        products: [(productId: String, quantity: Int, amount: Double)],
        dueDate: Date,
        notes: String,
        title: String,
        completion: @escaping (Result<(String, String), Error>) -> Void
    ) {
        guard let businessId = businessId, !businessId.isEmpty else {
            completion(.failure(WaveError.noBusinessId))
            return
        }
        
        print("Creating invoice with Customer ID: \(customerId) and \(products.count) products")
        
        let mutation = """
        mutation CreateInvoice($input: InvoiceCreateInput!) {
            invoiceCreate(input: $input) {
                didSucceed
                inputErrors {
                    message
                    code
                    path
                }
                invoice {
                    id
                    viewUrl
                    status
                    customer {
                        id
                        name
                    }
                    items {
                        product {
                            id
                            name
                        }
                        quantity
                        unitPrice
                        total {
                            value
                        }
                    }
                }
            }
        }
        """
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let invoiceItems: [[String: Any]] = products.map { product in
            [
                "productId": product.productId,
                "quantity": product.quantity,
                "unitPrice": String(format: "%.2f", product.amount)
            ]
        }
        
        let invoiceInput: [String: Any] = [
            "businessId": businessId,
            "customerId": customerId,
            "currency": "USD",
            "items": invoiceItems,
            "status": "SAVED",
            "dueDate": dateFormatter.string(from: dueDate),
            "memo": notes,
            "title": title
        ]
        
        let variables: [String: Any] = ["input": invoiceInput]
        
        print("Invoice variables: \(String(describing: variables))")
        
        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(waveToken)", forHTTPHeaderField: "Authorization")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: ["query": mutation, "variables": variables])
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(WaveError.noData))
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let data = json["data"] as? [String: Any],
                   let invoiceCreate = data["invoiceCreate"] as? [String: Any],
                   let didSucceed = invoiceCreate["didSucceed"] as? Bool,
                   didSucceed,
                   let invoice = invoiceCreate["invoice"] as? [String: Any],
                   let id = invoice["id"] as? String,
                   let viewUrl = invoice["viewUrl"] as? String {
                    completion(.success((viewUrl, id)))
                } else {
                    completion(.failure(WaveError.invalidResponse))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    private func findOrCreateCustomer(name: String, email: String) async throws -> String {
        print("Looking for existing customer with email: \(email)")
        
        if let existingCustomerId = try await searchCustomer(email: email) {
            print("Found existing customer with ID: \(existingCustomerId)")
            return existingCustomerId
        }
        
        print("No existing customer found, creating new customer...")
        return try await withCheckedThrowingContinuation { continuation in
            createCustomer(name: name, email: email) { result in
                switch result {
                case .success(let customerId):
                    print("Successfully created new customer with ID: \(customerId)")
                    continuation.resume(returning: customerId)
                case .failure(let error):
                    print("Failed to create customer: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func createRequest(query: String) -> URLRequest {
        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        createHeaders().forEach { request.addValue($0.value, forHTTPHeaderField: $0.key) }
        
        let body: [String: Any] = ["query": query]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            print("Error serializing request: \(error)")
        }
        
        return request
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
} 
