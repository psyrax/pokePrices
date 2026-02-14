#!/usr/bin/env swift
import AppKit
import CoreGraphics

let size: CGFloat = 1024

// Crear imagen
let image = NSImage(size: NSSize(width: size, height: size))
image.lockFocus()

let context = NSGraphicsContext.current!.cgContext

// Fondo con gradiente azul
let colors = [
    NSColor(red: 0.17, green: 0.35, blue: 0.65, alpha: 1.0).cgColor,
    NSColor(red: 0.25, green: 0.45, blue: 0.75, alpha: 1.0).cgColor,
]
let gradient = CGGradient(
    colorsSpace: CGColorSpaceCreateDeviceRGB(),
    colors: colors as CFArray,
    locations: [0, 1])!
context.drawLinearGradient(
    gradient,
    start: CGPoint(x: 0, y: size),
    end: CGPoint(x: 0, y: 0),
    options: [])

// Carta (rectángulo blanco con borde dorado)
let cardWidth: CGFloat = 420
let cardHeight: CGFloat = 580
let cardX = (size - cardWidth) / 2
let cardY: CGFloat = 150

let cardPath = NSBezierPath(
    roundedRect: NSRect(x: cardX, y: cardY, width: cardWidth, height: cardHeight),
    xRadius: 40, yRadius: 40)
NSColor.white.setFill()
cardPath.fill()

NSColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0).setStroke()
cardPath.lineWidth = 8
cardPath.stroke()

// Etiqueta de precio (amarillo dorado)
let priceW: CGFloat = 200
let priceH: CGFloat = 120
let priceX = size - priceW - 80
let priceY: CGFloat = 80

let pricePath = NSBezierPath(
    roundedRect: NSRect(x: priceX, y: priceY, width: priceW, height: priceH),
    xRadius: 20, yRadius: 20)
NSColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0).setFill()
pricePath.fill()

// Símbolo de dólar
let dollarSign = "$" as NSString
let attributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 90, weight: .bold),
    .foregroundColor: NSColor(red: 0.17, green: 0.35, blue: 0.65, alpha: 1.0),
]
dollarSign.draw(at: CGPoint(x: priceX + 70, y: priceY + 15), withAttributes: attributes)

image.unlockFocus()

// Guardar imagen
if let tiffData = image.tiffRepresentation,
    let bitmapImage = NSBitmapImageRep(data: tiffData),
    let pngData = bitmapImage.representation(using: .png, properties: [:])
{
    try! pngData.write(to: URL(fileURLWithPath: "icon_1024.png"))
    print("✅ Icono base creado: icon_1024.png")
}
