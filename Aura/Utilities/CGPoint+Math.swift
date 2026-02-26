import Foundation

extension CGPoint {
    func distance(to other: CGPoint) -> CGFloat {
        hypot(other.x - x, other.y - y)
    }

    func angle(to other: CGPoint) -> CGFloat {
        atan2(other.y - y, other.x - x)
    }

    static func + (lhs: CGPoint, rhs: CGVector) -> CGPoint {
        CGPoint(x: lhs.x + rhs.dx, y: lhs.y + rhs.dy)
    }

    static func - (lhs: CGPoint, rhs: CGPoint) -> CGVector {
        CGVector(dx: lhs.x - rhs.x, dy: lhs.y - rhs.y)
    }

    func lerp(to target: CGPoint, t: CGFloat) -> CGPoint {
        CGPoint(
            x: x + (target.x - x) * t,
            y: y + (target.y - y) * t
        )
    }
}

extension CGVector {
    var magnitude: CGFloat {
        hypot(dx, dy)
    }

    var normalized: CGVector {
        let m = magnitude
        guard m > 0 else { return CGVector(dx: 0, dy: 0) }
        return CGVector(dx: dx / m, dy: dy / m)
    }

    static func * (lhs: CGVector, rhs: CGFloat) -> CGVector {
        CGVector(dx: lhs.dx * rhs, dy: lhs.dy * rhs)
    }

    static func + (lhs: CGVector, rhs: CGVector) -> CGVector {
        CGVector(dx: lhs.dx + rhs.dx, dy: lhs.dy + rhs.dy)
    }
}
