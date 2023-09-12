//
//  File.swift
//
//
//  Created by Bartosz Polaczyk on 9/9/23.
//

import Foundation

class Queue<T> {
    class Node {
        var next: Node?
        var prev: Node?
        let value: T

        init(next: Node? = nil, prev: Node? = nil, value: T) {
            self.next = next
            self.prev = prev
            self.value = value
        }
    }
    private(set) var head: Node?
    private(set) var tail: Node?

    func enqueue(_ value: T) {
        let newNode = Node(prev: tail, value: value)
        guard let last = tail else {
            head = newNode
            tail = newNode
            return
        }
        last.next = newNode
        tail = newNode
    }

    func dequeue() -> T? {
        guard let first = head else {
            return nil
        }
        head = first.next
        if head == nil {
            tail = nil
        }
        return first.value
    }
}
