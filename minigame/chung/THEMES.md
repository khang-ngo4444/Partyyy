# Môi trường minigame và báo cáo asset

Toàn bộ 14 minigame đang hoạt động có lớp cảnh bao quanh. Ưu tiên cảnh 2.5D: hình render từ model có sẵn phủ lên vách liên tục, bầu trời và nền cùng tông. Đã bỏ nhóm cột/đạo cụ rời từng đặt quanh sân.

13 sân 3D dùng prefab `theme_backdrop.tscn`: bốn vách, trần và nền phong cảnh. Tank dùng `ScenicFrame`, một TextureRect phủ viewport sau bàn chơi 2D. Temporal Trails chưa hoạt động vẫn có cấu hình tương thích.

| Chủ đề | Minigame |
| --- | --- |
| Castle | Falling Floor, Laser Leap, Spotlight, Crown; khung Tank |
| Forest | Explosive, Count Animals, Minefield |
| Rocks | Magma, Rockslide |
| Palms | Wave Shelter |
| Workshop | Word Wars, Toy Factory, Paint |

Vách đặt ngoài sân, không có collider. Nền phong cảnh thấp hơn ngưỡng loại khi rơi; không tạo chỗ đứng an toàn mới. Khoảng trống riêng cho Laser giữ nguyên hành trình quét. Vách lở đá cao hơn camera ở đỉnh dốc. Với camera trực giao, chiều rộng bao cảnh tính theo viewport để Word Wars không hở hai bên trên màn hình rộng.

Shader `wallpaper.gdshader` lặp hình theo chiều ngang, giữ chiều cao hình theo từng chủ đề và kéo dài màu biên trời/nền theo chiều dọc. Hình không bị kéo cao theo toàn bộ phòng. Mỗi vách có bản sao material riêng. Spotlight dùng ánh sáng thật, không emission, để cảnh tối theo chu kỳ ghi nhớ.

## Asset đã tạo và nguồn

**Không dùng AI để sinh ảnh/model; không gọi dịch vụ tạo asset bên ngoài.** Tạo mới đúng 5 PNG 2048 × 512 bằng cách render model Kenney đã có trong repository. Tổng dung lượng PNG khoảng 710 KiB. Scene nguồn nhiều model chỉ phục vụ render, không được instantiate trong gameplay.

| File trong `scenery/` | Model nguồn có sẵn |
| --- | --- |
| `forest.png` | Nature Kit: `tree_pineRoundC.glb` |
| `rocks.png` | Nature Kit: `rock_tallH.glb` |
| `castle.png` | Castle Kit: `wall.glb` |
| `palms.png` | Nature Kit: `tree_palmShort.glb` |
| `workshop.png` | Furniture Kit: `bookcaseOpen.glb`, `books.glb` |

Nguồn nằm trong `asset/kenney_nature-kit`, `asset/kenney_castle-kit`, `asset/kenney_furniture-kit`. Các pack kèm `License.txt` ghi CC0. Giữ nguyên model và giấy phép gốc.

Prefab bao cảnh, scene render `scenery_bake.tscn`, các mesh và material được dựng/lưu bằng Godot MCP. Shader xử lý UV; script gameplay chỉ instantiate prefab và cấu hình vị trí/material. Không tạo cây node mỹ thuật bằng script điều khiển editor.

Render lại bằng Godot có GPU, từ thư mục project:

```powershell
& '<Godot_console.exe>' --path . --script res://tests/bake_scenery.gd
```

Sau khi render, reimport 5 PNG trong editor. Camera bake có kích thước viewport 2048 × 512 do runner đặt; preview cinematic trong editor dùng tỉ lệ viewport editor nên khung nhìn khác.

## Kiểm tra

- `run_theme_backdrop.gd`: 14 cấu hình, hình/material riêng, vách liên tục, không collider, nền dưới ngưỡng rơi, Spotlight nhận ánh sáng.
- `run_minigame_enclosures.gd -- --capture`: khởi động, render và kết thúc đủ 14 game; tia từ 8 mép màn hình gặp bao cảnh. Có ảnh riêng Spotlight lúc tối và camera lở đá trên đỉnh.
- `run_minigame_enclosures.gd -- --capture --wide`: lặp kiểm tra với viewport 21:9.
- Các runner Spotlight, Laser, Magma/clock, Paint, Minefield, Rockslide, Falling Floor, Machine Playground, movement, UI guidance và Word Wars/pool đều đạt.
- Kiểm tra nguồn render trong viewport MCP và ảnh GPU từng sân. Ảnh kiểm tra nằm ở `tests/runtime/enclosures/` (không đưa vào Git).

Kiểm tra GPU phát hiện lỗi crash khi Spotlight kết thúc sau khi đã render. Cách khôi phục layer được sửa: không đổi layer mesh của sân sắp hủy; tạm ẩn mesh nhân vật khi khôi phục layer để Godot gỡ liên kết ánh sáng trước. Tham chiếu lỗi engine: https://github.com/godotengine/godot/issues/121989. Runner GPU kiểm tra cả kết thúc ván để tránh bỏ sót lỗi này ở headless.

Chưa kiểm tra phiên Photon multiplayer trực tiếp.
