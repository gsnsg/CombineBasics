//
//  ContentView.swift
//  Combine Demo
//
//  Created by Sai Nikhit Gulla on 04/01/21.
//

import SwiftUI

// Model
struct User: Decodable, Identifiable {
    let id: Int
    let name: String
}

// View Models
import Combine

final class ViewModel: ObservableObject {
    @Published var time:String = ""
    @Published var users:[User] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    let dateFormatter: DateFormatter = {
       let df = DateFormatter()
        df.timeStyle = .medium
        return df
    }()
    init() {
        self.setupPublishers()
    }
    
    
    private func setupPublishers() {
        self.setupTimerPublisher()
        self.setupDataTaskPublisher()
    }
    
    private func setupTimerPublisher() {
        Timer.publish(every: 1, on: .main, in: .default)
            .autoconnect()
            .receive(on: RunLoop.main)
            .sink { value in
                self.time = self.dateFormatter.string(from: value)
            }
            .store(in: &cancellables)

    }
    
    private func setupDataTaskPublisher() {
        let url = URL(string: "https://jsonplaceholder.typicode.com/users")!
        URLSession.shared.dataTaskPublisher(for: url)
            .tryMap { (data, response)  in
                guard let httpResponse = response  as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }
                return data
            }.decode(type: [User].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }) { users in
                self.users = users
            }.store(in: &cancellables)
    }
    
}


// Views
struct ContentView: View {
    @StateObject var viewModel = ViewModel()
    var body: some View {
        VStack {
            Text(viewModel.time)
                .padding()
            
            List(viewModel.users) { user in
                Text(user.name)
            }
        }
        
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
