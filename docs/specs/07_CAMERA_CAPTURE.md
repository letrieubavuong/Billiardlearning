# CAMERA CAPTURE & SCENE RECONSTRUCTION (OUT OF ACTIVE SCOPE)

> [!IMPORTANT]
> **Roadmap Decision**: Camera capture, table detection, perspective correction, ball detection và automatic scene reconstruction nằm ngoài active product scope hiện tại.
> Manual Scene Editor là đường soạn thảo Scene chuẩn chính thức (PRIMARY).
> Các DTO/contract cũ (như `CameraCaptureDomain`, `source = CAMERA`) được giữ lại cho tính tương thích giao diện dữ liệu, không phát triển tính năng mới dựa trên camera.

## Target / Historical Reference Pipeline
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

## Historical Domain objects
- CaptureSession
- TableDetectionResult
- TableCorner
- PerspectiveTransformData
- BallDetection
- DetectionConfidence
- SceneReconstructionResult

## Authoring Priority
- Manual Scene Editor = PRIMARY
- Camera reconstruction = OUT OF ACTIVE SCOPE
