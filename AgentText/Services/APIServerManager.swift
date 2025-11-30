//
//  APIServerManager.swift
//  AgentText
//
//  Created by Nirav Jaiswal on 11/27/25.
//


//
//  APIServerManager.swift
//  AgentText
//
//  Manages the lifecycle of the AgentText API Server
//

import Foundation
import Combine

class APIServerManager: ObservableObject {
    @Published var isRunning = false
    @Published var serverOutput: [String] = []
    @Published var lastError: String?

    private var serverProcess: Process?
    private var outputPipe: Pipe?
    private var errorPipe: Pipe?

    private let serverPort: Int = 3000
    private let maxOutputLines = 100

    // Check if server is already running on port 3000
    func checkServerStatus() async -> Bool {
        guard let url = URL(string: "http://localhost:\(serverPort)/health") else { return false }

        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            if let httpResponse = response as? HTTPURLResponse {
                return httpResponse.statusCode == 200
            }
        } catch {
            return false
        }
        return false
    }

    func startServer() async throws {
        DispatchQueue.main.async {
            self.addOutput("🔄 Attempting to start API Server...")
        }
        
        // Check if already running
        if await checkServerStatus() {
            DispatchQueue.main.async {
                self.isRunning = true
                self.addOutput("✅ API Server is already running on port \(self.serverPort)")
            }
            return
        }

        // Use the API server from the project directory (not bundled)
        let projectPath = "/Users/nirav/development/AgentText/AgentText/APIServer"
        let serverPath = "\(projectPath)/api-server.ts"

        DispatchQueue.main.async {
            self.addOutput("📁 Looking for server at: \(serverPath)")
        }

        // Check if server file exists
        guard FileManager.default.fileExists(atPath: serverPath) else {
            let error = NSError(domain: "APIServerManager", code: 1,
                         userInfo: [NSLocalizedDescriptionKey: "API server file not found at \(serverPath)"])
            DispatchQueue.main.async {
                self.addOutput("❌ Server file not found!")
                self.lastError = error.localizedDescription
            }
            throw error
        }

        let serverDirectory = projectPath

        // Check for Bun first (preferred), then Node.js
        // Try multiple common paths for each runtime
        let bunPaths = [
            "/Users/nirav/.bun/bin/bun",
            "/opt/homebrew/bin/bun",
            "/usr/local/bin/bun"
        ]
        
        let nodePaths = [
            "/Users/nirav/.nvm/versions/node/v22.20.0/bin/node",
            "/opt/homebrew/bin/node",
            "/usr/local/bin/node"
        ]

        var executablePath: String?
        var args: [String] = []

        // Try Bun first
        for bunPath in bunPaths {
            if FileManager.default.fileExists(atPath: bunPath) {
                executablePath = bunPath
                args = ["run", serverPath]
                break
            }
        }
        
        // Fall back to Node.js if Bun not found
        if executablePath == nil {
            for nodePath in nodePaths {
                if FileManager.default.fileExists(atPath: nodePath) {
                    executablePath = nodePath
                    args = ["--import", "tsx", serverPath]
                    break
                }
            }
        }
        
        guard let executable = executablePath else {
            let error = NSError(domain: "APIServerManager", code: 2,
                         userInfo: [NSLocalizedDescriptionKey: "Neither Bun nor Node.js found. Please install Bun (recommended) or Node.js"])
            DispatchQueue.main.async {
                self.addOutput("❌ No JavaScript runtime found!")
                self.lastError = error.localizedDescription
            }
            throw error
        }

        DispatchQueue.main.async {
            self.addOutput("🔧 Using runtime: \(executable)")
            self.addOutput("📝 Arguments: \(args.joined(separator: " "))")
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = args
        process.currentDirectoryURL = URL(fileURLWithPath: serverDirectory)

        // Set up environment - include paths for bun, node, and other tools
        var environment = ProcessInfo.processInfo.environment
        environment["PORT"] = String(serverPort)
        
        // Ensure PATH includes common binary locations (apps launched from Finder don't inherit shell PATH)
        let additionalPaths = [
            "/Users/nirav/.bun/bin",
            "/Users/nirav/.nvm/versions/node/v22.20.0/bin",
            "/opt/homebrew/bin",
            "/usr/local/bin",
            "/usr/bin",
            "/bin"
        ]
        let existingPath = environment["PATH"] ?? "/usr/bin:/bin"
        environment["PATH"] = additionalPaths.joined(separator: ":") + ":" + existingPath
        
        // Set HOME for tools that need it
        environment["HOME"] = FileManager.default.homeDirectoryForCurrentUser.path
        
        process.environment = environment

        // Set up output pipes
        let outPipe = Pipe()
        let errPipe = Pipe()
        process.standardOutput = outPipe
        process.standardError = errPipe

        self.outputPipe = outPipe
        self.errorPipe = errPipe

        // Handle output
        outPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            if data.count > 0, let output = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    self?.addOutput(output)
                }
            }
        }

        // Handle errors
        errPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            if data.count > 0, let output = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    self?.addOutput("ERROR: \(output)")
                    self?.lastError = output
                }
            }
        }

        // Handle process termination
        process.terminationHandler = { [weak self] process in
            DispatchQueue.main.async {
                self?.isRunning = false
                self?.addOutput("Server stopped with exit code: \(process.terminationStatus)")
            }
        }

        do {
            try process.run()
            self.serverProcess = process

            DispatchQueue.main.async {
                self.isRunning = true
                self.addOutput("🚀 Starting API Server on port \(self.serverPort)...")
            }

            // Wait for server to start with retries
            var serverReady = false
            for attempt in 1...5 {
                try await Task.sleep(for: .seconds(1))
                if await checkServerStatus() {
                    serverReady = true
                    break
                }
                DispatchQueue.main.async {
                    self.addOutput("⏳ Waiting for server... (attempt \(attempt)/5)")
                }
            }

            // Verify server is running
            if serverReady {
                DispatchQueue.main.async {
                    self.addOutput("✅ API Server is ready at http://localhost:\(self.serverPort)")
                }
            } else {
                DispatchQueue.main.async {
                    self.addOutput("⚠️ Server started but health check not responding yet")
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.lastError = error.localizedDescription
                self.addOutput("❌ Failed to start server: \(error.localizedDescription)")
            }
            throw error
        }
    }

    func stopServer() {
        guard let process = serverProcess, process.isRunning else {
            DispatchQueue.main.async {
                self.isRunning = false
                self.addOutput("Server is not running")
            }
            return
        }

        process.terminate()

        // Clean up pipes
        outputPipe?.fileHandleForReading.readabilityHandler = nil
        errorPipe?.fileHandleForReading.readabilityHandler = nil

        serverProcess = nil
        outputPipe = nil
        errorPipe = nil

        DispatchQueue.main.async {
            self.isRunning = false
            self.addOutput("🛑 Server stopped")
        }
    }

    func restartServer() async throws {
        stopServer()
        try await Task.sleep(for: .seconds(1))
        try await startServer()
    }

    private func addOutput(_ output: String) {
        serverOutput.append(output)
        if serverOutput.count > maxOutputLines {
            serverOutput.removeFirst(serverOutput.count - maxOutputLines)
        }
    }

    func clearOutput() {
        DispatchQueue.main.async {
            self.serverOutput.removeAll()
            self.lastError = nil
        }
    }

    deinit {
        stopServer()
    }
}
