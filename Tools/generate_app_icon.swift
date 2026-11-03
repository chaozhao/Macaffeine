import AppKit

let outputPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "AppIcon-1024.png"

let canvasSize: CGFloat = 1024
let tileRect = NSRect(x: 100, y: 100, width: 824, height: 824)
let cornerRadius: CGFloat = 185.4

func srgb(_ hex: UInt32, alpha: CGFloat = 1) -> NSColor {
    NSColor(
        srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
        green: CGFloat((hex >> 8) & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255,
        alpha: alpha
    )
}

guard let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: Int(canvasSize),
    pixelsHigh: Int(canvasSize),
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
), let context = NSGraphicsContext(bitmapImageRep: rep) else {
    fatalError("无法创建位图上下文")
}

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = context

NSColor.clear.setFill()
NSRect(x: 0, y: 0, width: canvasSize, height: canvasSize).fill()

let tile = NSBezierPath(roundedRect: tileRect, xRadius: cornerRadius, yRadius: cornerRadius)

// 图标底部投影
context.saveGraphicsState()
let tileShadow = NSShadow()
tileShadow.shadowColor = NSColor.black.withAlphaComponent(0.28)
tileShadow.shadowBlurRadius = 26
tileShadow.shadowOffset = NSSize(width: 0, height: -10)
tileShadow.set()
srgb(0xE85208).setFill()
tile.fill()
context.restoreGraphicsState()

// 橙色渐变与光影
context.saveGraphicsState()
tile.addClip()

let gradient = NSGradient(colors: [srgb(0xFFB23A), srgb(0xF0560A)])!
gradient.draw(in: tileRect, angle: -45)

let sheen = NSGradient(colors: [
    NSColor.white.withAlphaComponent(0.16),
    NSColor.white.withAlphaComponent(0)
])!
sheen.draw(in: NSRect(x: 100, y: 640, width: 824, height: 284), angle: -90)

let vignette = NSGradient(colors: [
    NSColor.clear,
    NSColor.black.withAlphaComponent(0.08)
])!
vignette.draw(
    fromCenter: NSPoint(x: 512, y: 512),
    radius: 300,
    toCenter: NSPoint(x: 512, y: 512),
    radius: 620,
    options: []
)
context.restoreGraphicsState()

// 内侧高光描边
context.saveGraphicsState()
let border = NSBezierPath(
    roundedRect: tileRect.insetBy(dx: 1.5, dy: 1.5),
    xRadius: cornerRadius - 1.5,
    yRadius: cornerRadius - 1.5
)
border.lineWidth = 3
NSColor.white.withAlphaComponent(0.20).setStroke()
border.stroke()
context.restoreGraphicsState()

// 白色电源符号
let center = NSPoint(x: 512, y: 458)
let radius: CGFloat = 168
let strokeWidth: CGFloat = 60
let gapHalfAngle: CGFloat = 30

context.saveGraphicsState()
let glyphShadow = NSShadow()
glyphShadow.shadowColor = NSColor.black.withAlphaComponent(0.16)
glyphShadow.shadowBlurRadius = 12
glyphShadow.shadowOffset = NSSize(width: 0, height: -6)
glyphShadow.set()
NSColor.white.setStroke()

let ring = NSBezierPath()
ring.appendArc(
    withCenter: center,
    radius: radius,
    startAngle: 90 + gapHalfAngle,
    endAngle: 90 - gapHalfAngle + 360,
    clockwise: false
)
ring.lineWidth = strokeWidth
ring.lineCapStyle = .round
ring.stroke()

let stem = NSBezierPath()
stem.move(to: NSPoint(x: center.x, y: center.y + radius + 108))
stem.line(to: NSPoint(x: center.x, y: center.y + radius * 0.32))
stem.lineWidth = strokeWidth
stem.lineCapStyle = .round
stem.stroke()
context.restoreGraphicsState()

NSGraphicsContext.restoreGraphicsState()

guard let png = rep.representation(using: .png, properties: [:]) else {
    fatalError("无法编码 PNG")
}
try png.write(to: URL(fileURLWithPath: outputPath))
print("已生成 \(outputPath)")
