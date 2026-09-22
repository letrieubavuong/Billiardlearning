# DOMAIN MODEL

## Aggregate chính

### Lesson
- id
- title
- description
- chapterId
- order
- sections
- tags

### LessonSection
- id
- title
- order
- blocks

### LessonBlock
Các subtype:
- TextBlock
- ImageBlock
- FormulaBlock
- NoteBlock
- SceneBlock
- AnimationBlock
- TechniqueBlock
- NumberSystemBlock
- ExerciseBlock

### BilliardScene
- id
- title
- tableConfig
- balls
- trajectories
- annotations
- cueSetup?
- simulationProfileId?

### BallState
- id
- role: CUE | OBJECT | TARGET | AUXILIARY
- position: Vec2
- velocity: Vec2
- angularVelocity: Vec3
- radius
- mass
- color/style
- motionState

### Trajectory
- id
- ballId
- segments
- source: MANUAL | PHYSICS

### PathSegment
Subtype đề xuất:
- LineSegment
- CushionSegment
- CollisionSegment
- CurveSegment
- StopSegment

### Technique
- id
- name
- category
- level
- theory
- sceneIds
- tags

### NumberSystem
- id
- name
- variables
- formulaDefinition
- diamondMapping
- examples
- notes

### Exercise
- id
- prompt
- initialSceneId
- expectedSolution
- scoringRule
- hints

## Value Objects

- Vec2
- Vec3
- NormalizedPoint
- Angle
- Speed
- SpinVector
- CueContactPoint
- PowerLevel
- CushionId

## Quy tắc

- Domain model immutable khi có thể.
- Dùng copy/new state thay cho mutate UI-driven.
- Không chứa Android Context.
- Không chứa annotation Room trong domain package.
