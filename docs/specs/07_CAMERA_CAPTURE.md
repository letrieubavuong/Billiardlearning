# CAMERA CAPTURE & SCENE RECONSTRUCTION

## Pipeline
1. Capture image/frame.
2. Detect table/playfield.
3. Detect/adjust 4 corners.
4. Perspective transform/homography.
5. Detect carom balls.
6. Classify red/white/yellow.
7. Estimate centers + confidence.
8. Convert to TablePoint.
9. Build candidate BilliardScene.
10. Manual correction.
11. Confirm/save.

## Domain objects
- CaptureSession
- TableDetectionResult
- TableCorner
- PerspectiveTransformData
- BallDetection
- DetectionConfidence
- SceneReconstructionResult

## UX rule
Không yêu cầu AI perfect. Manual correction là phần chính thức của nghiệp vụ.

## First target
Carom/3-cushion trước. Pool/snooker là extension sau.

## Boundary
Camera implementation không ghi trực tiếp Lesson DB. Output cuối là `BilliardScene`/candidate scene.
