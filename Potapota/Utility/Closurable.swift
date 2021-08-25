//
//  Closurable.swift
//  Walking
//
//  Created by noguchi on 2021/08/24.
//

import UIKit

protocol Closurable: AnyObject {}

extension Closurable {
    /// Closure内部で自身のプロパティを設定出来る
    ///
    /// - Parameter closure: closure
    /// - Returns: self
    func then(_ closure: (Self) -> Void) -> Self {
        closure(self)
        return self
    }

    private func getContainer(on controlEvents: UIControl.Event? = nil, for closure: @escaping (Self) -> Void) -> Container<Self> {
        weak var caller = self
        let container = Container(closure: closure, caller: caller)
        var key = Unmanaged.passUnretained(self).toOpaque().debugDescription
        if let controlEvents = controlEvents {
           key += "_" + controlEvents.rawValue.description
        }
        objc_setAssociatedObject(self, key, container, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return container
    }
}

extension NSObject: Closurable {}

extension Closurable where Self: UIButton {
    func onTap(_ closure: @escaping (Self) -> Void) {
        objc_removeAssociatedObjects(self)
        let container = getContainer(for: closure)
        addTarget(container, action: container.action, for: .touchUpInside)
    }
}

extension Closurable where Self: UIControl {
    /// - caution: TableViewCellなど同一オブジェクトを再利用する可能性がある場合、1アクションに複数のイベントが登録される可能性あり。
    /// その場合はClosurableを使用しないなどの検討を行うように。
    func on(_ controlEvents: UIControl.Event, closure: @escaping (Self) -> Void) {
        let container = getContainer(on: controlEvents, for: closure)
        addTarget(container, action: container.action, for: controlEvents)
    }
}

extension Closurable where Self: UIBarButtonItem {
    init(title: String, style: UIBarButtonItem.Style = .plain, closure: @escaping (Self) -> Void) {
        self.init()
        self.title = title
        self.style = style
        onTap(closure)
    }
    
    init(image: UIImage?, style: UIBarButtonItem.Style = .plain, closure: @escaping (Self) -> Void) {
        self.init()
        self.image = image
        self.style = style
        onTap(closure)
    }
    
    func onTap(_ closure: @escaping (Self) -> Void) {
        let container = getContainer(for: closure)
        self.target = container
        self.action = container.action
    }
}

extension Closurable where Self: UIGestureRecognizer {
    init(closure: @escaping (Self) -> Void) {
        self.init()
        on(closure)
    }
    
    func on(_ closure: @escaping (Self) -> Void) {
        let container = getContainer(for: closure)
        addTarget(container, action: container.action)
    }
}

// MARK: - Private
final private class Container<T: Closurable> {
    var closure: (T) -> Void
    weak var caller: T?
    
    var action: Selector {
        return #selector(selector)
    }
    
    init(closure: @escaping (T) -> Void, caller: T?) {
        self.closure = closure
        self.caller = caller
    }
    
    @objc private func selector() {
        guard let caller = caller else { return }
        closure(caller)
    }
}
