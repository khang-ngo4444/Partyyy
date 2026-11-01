# Âm thanh của game

Mọi file ở đây là **placeholder**: nhạc do `tool/tao_am_thanh_placeholder.py` tổng hợp, SFX chép từ bộ Kenney CC0.

## Thay file

Ghi đè đúng tên file là xong, không phải sửa code. Có thể đổi định dạng: game tìm `.ogg`, rồi `.mp3`, rồi `.wav`
theo cùng tên (nhớ xoá file cũ và `.import` của nó). Không cần bật loop khi import, code tự đặt lặp theo loại bản nhạc.

## Nhạc: `nhac/<mã>/`

`<mã>` là tên file scene của trò.

| File | Khi phát | Lặp |
|---|---|---|
| `dem_nguoc.ogg` | Thẻ luật + đếm ngược | có |
| `choi.ogg` | Đang chơi | có |
| `ket_qua.ogg` | Bảng kết quả (khoảng 5 giây) | không |

Thiếu `dem_nguoc` hoặc `ket_qua` thì trò dùng `choi`; thiếu cả `choi` thì im lặng.

| Thư mục | Nội dung |
|---|---|
| `menu` | Menu chính, gồm cả màn tạo phòng (chỉ cần `choi.ogg`) |
| `ban_co` | Bàn cờ chính (chỉ cần `choi.ogg`) |
| `tank_battle`, `breaking_blocks`, `laser_leap`, `spotlights`, `explosive`, `magma`, `crown` | Minigame |
| `word_wars`, `dem_thu`, `lo_da`, `toy_factory`, `wave_hide`, `minefield`, `paint` | Minigame |

## SFX: `sfx/`

| File | Khi phát |
|---|---|
| `bam_nut` | Bấm nút, tab, mục danh sách ở mọi giao diện |
| `xuc_xac` | Tung xúc xắc |
| `buoc_chan` | Quân đi một ô |
| `luot_moi` | Sang lượt người khác |
| `nhan_tien` | Có người được cộng tiền |
| `mat_mau` | Có người mất máu trên bàn |
| `nhan_cup` | Có người được cúp |
| `dung_do` | Dùng vật phẩm |
| `thang_van` | Thắng cả ván |
| `dem_nguoc` | Mỗi giây đếm ngược minigame |
| `bat_dau` | Minigame bắt đầu |
| `thang` / `thua` | Bạn về nhất / không về nhất minigame |
| `danh` / `chuong` | Đòn đánh / đòn chưởng trúng |
| `loai` | Có người bị loại |
| `ban` | Xe tăng bắn, cầu lửa Magma |
| `no` | Xe tăng nổ, mìn nổ |
| `vo` | Tường tank vỡ, sàn Breaking Blocks sập |
| `chuyen_bom` | Bom đổi người cầm |
| `doi_mien` | Vương miện đổi chủ |
| `go_chu` | Bạn gõ đúng một chữ (Word Wars) |
| `tra_loi` | Bạn hoàn thành từ / chốt đáp án |
| `ve_dich` | Có người về đích (Lò Đá) |
| `phun` | Phun súng (Toy Factory) |
| `laser` | Tia laser mới sắp quét |
| `song` | Sóng sắp tới (Wave Hide) |
| `son` | Vung cọ (Paint) |

## Sinh lại placeholder

```bash
python tool/tao_am_thanh_placeholder.py
```

Script bỏ qua file đã tồn tại, nên không đè file bạn đã thay. `--ghi-de` mới sinh lại toàn bộ.
