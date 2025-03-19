//
//  ContentView.swift
//  ConcurrencyExample
//
//  Created by Alina Nicorescu on 06.03.2025.
//

import SwiftUI

struct ContentView: View {
    
    @MainActor
    class TimeStore {
    //actor TimeStore {
        
        var timestamps: [Int: Date] = [:]
        
        func addStamp(task: Int, date: Date) {
            timestamps[task] = date
        }
    }
    
    struct MyStruct  {
        var myResult: Date {
            get async {
                do {
                    return try await self.getTime()
                } catch {
                    return Date()
                }
            }
        }
        
        func getTime() async throws -> Date {
            try await Task.sleep(until: .now + .seconds(5))
            return Date()
        }
    }
    
    var body: some View {
        Button(action: {
            Task {
                await doSomethingActor()
            }
        }) {
            Text("Do something")
        }
    }
    
    func doSomethingActor() async {
        
        let store = TimeStore()
        
        await withTaskGroup(of: Void.self) { group in
            for i in 1...5 {
                group.addTask {
                    await store.addStamp(task: i, date: await takesTooLong())
                }
            }
        }
        
        for (task, date) in store.timestamps {
            print("Task = \(task), Date = \(date)")
        }
    }
    
    func doSomethingTask() async {
        let myStruct = MyStruct()
        Task {
            let date = await myStruct.myResult
            print(date)
        }
    }
    
    func doSomethingTaskGroup() async {
        
        var timestamps: [Int: Date] = [:]
        
        await withTaskGroup(of: (Int, Date).self) { group in
            for i in 1...5 {
                group.addTask {
                    return (i, await takesTooLong())
                }
            }
            
            for await (task , date) in group {
                timestamps[task] = date
            }
        }
        
        for (task, date) in timestamps {
            print("Task = \(task), Date = \(date)")
        }
    }
    
    func doSomethingTaskGroupDataRace() async {
        
        var timestamps: [Int: Date] = [:]
        
        await withTaskGroup(of: Void.self) { group in
            for i in 1...5 {
                group.addTask {
                    //data race
                    timestamps[i] = await takesTooLong()
                }
            }
        }
    }
     
    func doSomethingSimple() async {
        print("Start \(Date())")
        async let result = takesTooLong()
        print("After async-let \(Date())")
        print("result = \(await result)")
        print("End \(Date())")
    }
    
    func takesTooLong() async -> Date {
        do {
            try await Task.sleep(until: .now + .seconds(5))
        } catch {
            return Date()
        }
        print("Async task completed at \(Date())")
        return Date()
    }
}

#Preview {
    ContentView()
}
