import Foundation

nonisolated struct EditingHistory: Equatable, Sendable {
    private(set) var document: EditingDocument
    private(set) var canUndo = false
    private(set) var canRedo = false

    private let capacity: Int
    private var undoStack: [EditingDocument] = []
    private var redoStack: [EditingDocument] = []
    private var activeCoalescingKey: String?

    init(document: EditingDocument, capacity: Int = 50) {
        precondition(capacity > 0, "History capacity must be positive")
        self.document = document
        self.capacity = capacity
    }

    mutating func apply(
        _ command: EditingCommand,
        coalescingKey: String? = nil
    ) throws {
        let nextDocument = try EditingReducer.reduce(document, command: command)
        guard nextDocument != document else { return }

        if coalescingKey == nil || coalescingKey != activeCoalescingKey {
            undoStack.append(document)
            if undoStack.count > capacity {
                undoStack.removeFirst(undoStack.count - capacity)
            }
        }

        document = nextDocument
        redoStack.removeAll()
        activeCoalescingKey = coalescingKey
        updateAvailability()
    }

    mutating func endCoalescing() {
        activeCoalescingKey = nil
    }

    @discardableResult
    mutating func undo() -> Bool {
        guard let previous = undoStack.popLast() else { return false }
        redoStack.append(document)
        document = previous
        activeCoalescingKey = nil
        updateAvailability()
        return true
    }

    @discardableResult
    mutating func redo() -> Bool {
        guard let next = redoStack.popLast() else { return false }
        undoStack.append(document)
        document = next
        activeCoalescingKey = nil
        updateAvailability()
        return true
    }

    private mutating func updateAvailability() {
        canUndo = !undoStack.isEmpty
        canRedo = !redoStack.isEmpty
    }
}
