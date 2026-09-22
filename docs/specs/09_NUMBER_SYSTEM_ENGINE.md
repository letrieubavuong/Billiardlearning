# NUMBER SYSTEM ENGINE

## NumberSystem là domain riêng
Không phải Note, không phải enum renderer.

## Data model gợi ý
- id
- name
- description
- category
- variables[]
- expression/model
- tableMappings[]
- conditions[]
- corrections[]
- defaultCueInstruction optional
- exampleSceneIds[]
- tags[]
- version/status

## Engine
- validate inputs
- evaluate formula/model
- map diamonds/values
- explain calculation steps
- return result independent from UI

## Bất biến
Không có `if (systemName == ...)` cho từng hệ.
Nếu một hệ cần logic đặc biệt, biểu diễn bằng strategy/plugin data model có type rõ, không theo display name.
