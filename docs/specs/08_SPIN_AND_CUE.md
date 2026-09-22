# SPIN & CUE STRIKE

## Cue input

Người dùng điều chỉnh:
- aim angle
- power
- contactX [-1,1]
- contactY [-1,1]
- optional cue elevation

## Mapping

CueStrikeModel chuyển input thành:
- initial linear velocity
- initial angular velocity

Mapping phải nằm trong domain/simulation, không nằm trong slider UI.

## Spin components

- top/back spin
- side spin
- combined spin
- optional masse/swerve ở phase sau

## Motion states

Sliding -> Rolling là chuyển trạng thái vật lý quan trọng.
Top/back spin phải ảnh hưởng cue ball sau va chạm theo mô hình đã chọn.

## UI biểu diễn

Hiển thị một cue-ball contact selector 2D liên tục, không chỉ 9 preset.
Preset chỉ là shortcut.
