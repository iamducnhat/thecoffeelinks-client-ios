import Foundation

/// Coordinator for managing background content refresh tasks.
/// Prevents duplication and handles prioritization logic.
actor ContentRefreshCoordinator {
    private var activeTasks: [String: Task<Void, Never>] = [:]
    
    /// Schedules a refresh task if one is not already running for the given ID.
    /// - Parameters:
    ///   - id: Unique identifier for the resource (e.g. "menu", "home_products")
    ///   - priority: The priority of the task.
    ///   - operation: The async operation to perform.
    func schedule(id: String, priority: TaskPriority = .medium, operation: @escaping @Sendable () async -> Void) {
        // If a task for this ID is already running, do nothing (deduplication)
        if activeTasks[id] != nil {
            return
        }
        
        let task = Task(priority: priority) {
            await operation()
            // Cleanup after completion
            self.taskDidFinish(id: id)
        }
        
        activeTasks[id] = task
    }
    
    /// Returns true if a task with the given ID is currently running.
    func isRefreshing(id: String) -> Bool {
        activeTasks[id] != nil
    }
    
    /// Cancels a specific task if running.
    func cancel(id: String) {
        activeTasks[id]?.cancel()
        activeTasks[id] = nil
    }
    
    private func taskDidFinish(id: String) {
        activeTasks[id] = nil
    }
}
