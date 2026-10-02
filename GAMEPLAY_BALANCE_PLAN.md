# Kế hoạch vũ khí và cân bằng gameplay

## Baseline đang dùng

- 40% đất, 20% máu, 25% tiền, 15% trang bị.
- 10 máu tối đa; ô máu hồi 3; ô tiền cho 15 vàng.
- Mở rương tốn 100 vàng. Có 4 rương ngẫu nhiên: 3 giả, 1 thật.
- Checkpoint cá nhân mở mỗi 18 bước.
- Thuế mặc định: 2 máu hoặc 10 vàng; đất/trang bị chuyển một đơn vị nếu người trả có.
- Hạng 1 minigame nhận Súng một phát. Hạng 2 nhận 30 vàng, các hạng sau giảm 10,
  tối thiểu 5 vàng.

Các số này đều nằm trong bước **Cài đặt màn chơi** của chủ phòng, trừ mức tối thiểu 5 vàng.

## Vũ khí một phát

Nên làm vũ khí đầu tiên theo kiểu hitscan có ngắm, không tự khóa mục tiêu:

1. Khi có súng, camera tự chuyển sang góc nhìn thứ nhất; ngắm bằng tâm màn hình và bấm
   chuột trái để bắn. Không thể bắn khi quân đang di chuyển, chọn đường hoặc trong minigame.
   Bắn trúng hay trượt đều tiêu súng.
2. Tầm hiện tại 35 m, sát thương khởi điểm 3/10 máu, không headshot. Khiên chặn trọn một phát.
3. Client chỉ gửi `origin + direction`; master kiểm người bắn, súng trong túi, trạng thái bàn,
   vị trí phát tia, tầm và raycast rồi mới phát kết quả. Không nhận thẳng “player bị trúng” từ client.
4. Vệt đạn, giật camera và âm thanh là hiệu ứng cục bộ; máu, tiêu súng, chết và hồi sinh nằm
   trong gói trạng thái bàn hiện có.
5. Nếu máu về 0, người chơi hồi đầy tại checkpoint cá nhân. Baseline không mất vàng để tránh
   snowball; chỉ mất nhịp vị trí.

Stop condition cho lát cắt đầu tiên: hai client có thể ngắm, bắn trúng/trượt đúng một lần,
master cho cùng một kết quả, khiên chặn được, và người chết về đúng checkpoint.

## Cân bằng vàng và độ dài ván

Mục tiêu playtest đầu tiên: một ván 4 người dài 6–10 vòng bàn, không ai có khả năng thử rương
trước vòng 3. Với baseline 25% ô tiền × 15 vàng, một lượt đi cho kỳ vọng 3,75 vàng từ bàn;
phần lớn tốc độ gom vàng đến từ thưởng minigame. Hạng 1 nhận sức mạnh tấn công nhưng không
nhận vàng, tạo cơ chế bắt kịp cho người xếp sau.

Ba biến nên chỉnh theo thứ tự:

1. `Vàng hạng 2 minigame` và `Vàng giảm mỗi hạng` để điều khiển tốc độ toàn phòng.
2. `Vàng nhận từ ô` để giảm độ lệch do xúc xắc.
3. `Giá mở rương` chỉ đổi sau cùng vì nó ảnh hưởng trực tiếp thời lượng toàn ván.

Baseline hiện tại là chế độ khó: rương giả vẫn thu đủ 100 vàng. Nếu playtest cho thấy người mở
rương giả gần như hết cơ hội quay lại, thử hoàn 60 vàng khi gặp rương giả (chi phí thực 40)
trước khi hạ giá rương thật. Cách này vẫn giữ khoảnh khắc phải tích đủ 100 nhưng giảm hình phạt
do đoán sai.

## Dữ liệu cần ghi khi playtest

- Vòng đầu tiên có người đạt 100 vàng.
- Số lần mở rương và vàng còn lại của từng người.
- Chênh lệch vàng cao nhất/thấp nhất sau mỗi minigame.
- Tỷ lệ súng bắn trúng, số lần khiên chặn, số lần chết.
- Tổng thời gian ván và số vòng trước khi mở đúng rương.

Chỉ cân bằng sau ít nhất 10 ván 4 người; không đổi nhiều hơn một nhóm biến trong cùng một đợt.
