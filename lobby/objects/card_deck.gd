class_name CardDeck
extends Resource

## Ảnh bộ bài dùng chung cho Card, CommunityBoard và LiarBar — một chỗ duy nhất, gán trong
## Inspector của card_deck.tres. Đổi bộ bài: kéo ảnh mới vào đây, không phải sửa code.

## 52 mặt theo thứ tự `Card.card_index`: chuồn, rô, cơ, bích; mỗi chất A, 2..10, J, Q, K.
@export var mat: Array[Texture2D] = []
@export var lung: Texture2D
@export var joker: Texture2D


## Ảnh mặt của lá thứ `idx`. Ngoài 0..51 là joker.
func anh(idx: int) -> Texture2D:
	return mat[idx] if idx >= 0 and idx < mat.size() else joker
