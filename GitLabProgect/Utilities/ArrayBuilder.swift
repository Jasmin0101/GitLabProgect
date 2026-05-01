//
//  ArrayBuilder.swift
//  GitLabProgect
//
//  Created by Жасмина on 30.04.2026.
//

@resultBuilder
public enum ArrayBuilder<Element> {
  public typealias Component = [Element]
  public typealias Expression = Element

  public static func buildExpression(_ element: Expression) -> Component {
    [element]
  }

  public static func buildExpression(_ element: Expression?) -> Component {
    element.map { [$0] } ?? []
  }

  public static func buildExpression(_ component: Component) -> Component {
    component
  }

  public static func buildOptional(_ component: Component?) -> Component {
    component ?? []
  }

  public static func buildEither(first component: Component) -> Component {
    component
  }

  public static func buildEither(second component: Component) -> Component {
    component
  }

  public static func buildArray(_ components: [Component]) -> Component {
    Array(components.joined())
  }

  public static func buildBlock(_ components: Component...) -> Component {
    Array(components.joined())
  }

  public static func build(@ArrayBuilder<Element> _ builder: () -> [Element]) -> [Element] {
    builder()
  }
}

public extension Array {
  init(@ArrayBuilder<Element> _ builder: () -> [Element]) {
    self = builder()
  }
}
