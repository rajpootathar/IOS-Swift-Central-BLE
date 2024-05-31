//
//  ContentView.swift
//  CoreBluetooth-Central
//
//  Created by Tahir Mac aala on 30/05/2024.
//

import SwiftUI
import CoreBluetooth

struct ContentView: View {
    @ObservedObject var bluetoothManager = BluetoothManager.shared
    var body: some View {
        NavigationView {
            VStack {
                NavigationLink {
                    List(bluetoothManager.message, id: \.self) { message in
                            Text(message)
                        }
                } label: {
                    List(bluetoothManager.discoveredPeripherals, id: \.identifier) { peripheral in
                            Text(peripheral.name ?? "Unknown Device")}
                        }
                    }
                .navigationTitle("Central Device")
                .background(Color.white)
            }
        Button(action: {
//            exit(0)
            assert(1==2,"Crashed")
//            fatalError("Simulated crash for testing")
        }, label: {
            Text("Crash")
        })
    }
}

#Preview {
    ContentView()
}
