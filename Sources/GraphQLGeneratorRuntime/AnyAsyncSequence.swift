
/// A type-erased AsyncSequence. This exists because we cannot qualify `AsyncSequence` opaque types with `Element`
/// constraints in our SubscriptionProtocol.
public struct AnyAsyncSequence<Element: Sendable>: AsyncSequence, Sendable {
    public typealias Element = Element
    public typealias AsyncIterator = AnyAsyncIterator

    private let makeAsyncIteratorClosure: @Sendable () -> AsyncIterator

    public init<T: AsyncSequence>(_ sequence: T) where T.Element == Element, T: Sendable {
        makeAsyncIteratorClosure = {
            AnyAsyncIterator(sequence.makeAsyncIterator())
        }
    }

    public func makeAsyncIterator() -> AsyncIterator {
        AnyAsyncIterator(makeAsyncIteratorClosure())
    }

    public struct AnyAsyncIterator: AsyncIteratorProtocol, @unchecked Sendable {
        private let nextClosure: () async throws -> Element?

        public init<T: AsyncIteratorProtocol>(_ iterator: T) where T.Element == Element {
            var iterator = iterator
            nextClosure = { try await iterator.next() }
        }

        public func next() async throws -> Element? {
            try await nextClosure()
        }
    }
}

public extension AsyncSequence where Self: Sendable, Element: Sendable {
    /// Create a type erased version of this sequence
    func any() -> AnyAsyncSequence<Element> {
        AnyAsyncSequence(self)
    }
}
