# Flappy MacBook

用 MacBook 开合盖角度控制 Flappy Bird 小鸟高度的 macOS SpriteKit 游戏，基于 Apple Silicon 未公开传感器实时读取盖合角度并线性映射到画面位置。

## Demo

https://github.com/user-attachments/assets/62a7f5a7-55f4-42e3-af1f-baa7d1530e5c

## How It Works

- 盖合角度 30°–90° 线性映射到游戏画面高度
- `currentY = currentY × 0.7 + targetY × 0.3` lerp 平滑
- 传感器不可用时自动降级为鼠标控制

## Requirements

- macOS 14.0+, Apple Silicon MacBook

## Dependencies

- [AppleSiliconSensor](https://github.com/vnixx/apple-silicon-accelerometer) — Apple Silicon 未公开传感器读取

## Credits

- 原版 [FlappySwift](https://github.com/newlinedotco/FlappySwift) by Nate Murray & Ari Lerner
- Based on code by [Matthias Gall](http://digitalbreed.com/2014/how-to-build-a-game-like-flappy-bird-with-xcode-and-sprite-kit)
