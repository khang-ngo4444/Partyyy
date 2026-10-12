# SWOT Analysis — PartyBash

**Phạm vi đánh giá:** trạng thái project hiện tại theo `readme.md`, `ROADMAP.md`, `MINIGAME.md`, `GUIDE.md` và cấu hình `project.godot`.

## 1. Tổng quan dự án

PartyBash là game party 3D multiplayer theo vòng lặp:

> **Interactive lobby → bàn cờ party → minigame → vòng bàn tiếp theo**

Công nghệ chính:

- Godot 4.7.1
- GDScript
- Photon Fusion Godot 3, Shared Authority
- Photon Cloud
- Tối đa định hướng khoảng 10 người/phòng
- Có lobby 3D, board-game framework và hệ thống minigame mở rộng

Project hiện đang ở giai đoạn **prototype nâng cao / vertical slice mở rộng**, chưa phải sản phẩm hoàn thiện. Nền tảng kỹ thuật khá lớn, nhưng hướng gameplay và phạm vi tính năng vẫn đang được tinh chỉnh.

---

# 2. SWOT Matrix

| | Tích cực | Tiêu cực |
|---|---|---|
| **Nội bộ** | **Strengths — Điểm mạnh** | **Weaknesses — Điểm yếu** |
| **Bên ngoài** | **Opportunities — Cơ hội** | **Threats — Rủi ro / Đe dọa** |

---

## A. Strengths — Điểm mạnh

### 1. Ý tưởng sản phẩm dễ hiểu và có tiềm năng tạo trải nghiệm xã hội

Mô hình kết hợp giữa lobby tương tác, bàn cờ và minigame ngắn tạo ra một gameplay loop rõ ràng. Người chơi không chỉ vào menu để chọn game mà có thể di chuyển, tương tác và khám phá không gian chung.

Điểm này giúp PartyBash có bản sắc tốt hơn một game chỉ gồm danh sách minigame rời rạc.

### 2. Kiến trúc multiplayer được thiết kế tương đối bài bản

Project đã có các nguyên tắc mạng rõ ràng:

- Dùng replicated state cho trạng thái lâu dài.
- Dùng RPC cho sự kiện rời rạc, không gửi dữ liệu mỗi frame.
- Tách master client, object owner và remote client.
- Có hướng xử lý late join.
- Có tài liệu riêng về các lỗi Photon đã gặp và cách kiểm thử hai máy.

Các nguyên tắc này được ghi khá rõ trong `GUIDE.md` và phần multiplayer architecture của `readme.md`.

Đây là lợi thế đáng kể so với nhiều prototype multiplayer chỉ chạy được trên một máy hoặc phụ thuộc quá nhiều vào logic cục bộ.

### 3. Framework minigame có tính mở rộng

Theo `MINIGAME.md`, minigame được tổ chức theo hợp đồng tương đối rõ:

```gdscript
func bat_dau(nguoi_choi: Array, hat_giong: int) -> void
signal xong(xep_hang: Array)
```

Bàn cờ không cần biết luật chi tiết của từng minigame. Việc thêm minigame mới chủ yếu đi qua framework chung và danh sách đăng ký.

Đây là thiết kế tốt cho việc:

- Thêm game mới.
- Tái sử dụng hệ thống camera, timer, ranking và kết thúc game.
- Giảm coupling giữa board game và minigame.

### 4. Có nhiều nội dung tương tác sẵn trong lobby

Lobby không chỉ là phòng chờ. Project đã định hướng hoặc triển khai nhiều hoạt động như:

- Poker, xì dách và bài nói dối.
- Cờ vua, cờ tướng, caro.
- Xúc xắc.
- Phi tiêu.
- Bóng rổ.
- Đua gà.
- Đập chuột chũi.
- Penguin Cross.
- Tháp Hà Nội.

Điều này tạo cảm giác thế giới game phong phú và có thể giúp người chơi vẫn có thứ để làm ngay cả khi chưa bắt đầu một vòng board game.

### 5. Có bằng chứng kiểm thử thực tế, không chỉ là thiết kế trên giấy

`ROADMAP.md` ghi lại nhiều lần kiểm thử cụ thể:

- Hai máy thật qua Photon Cloud.
- Kiểm tra late join.
- Kiểm tra trạng thái replicated.
- Kiểm tra kích thước bàn và va chạm.
- Kiểm tra giao diện chat.
- Kiểm tra đồng hồ đếm ngược.
- Kiểm tra quy trình export build.
- Kiểm tra một số lỗi lệch trạng thái và đã sửa.

Việc ghi lại số đo, nguyên nhân lỗi và cách sửa là một điểm mạnh về quy trình phát triển.

### 6. Chi phí asset ban đầu thấp

Project sử dụng nhiều asset miễn phí từ Kenney, KayKit và một số nguồn khác. `CREDITS.md` cũng đã có hệ thống ghi nhận nguồn và license tương đối rõ.

Điều này phù hợp với một đồ án hoặc prototype cần nhanh chóng kiểm chứng gameplay mà không phải tự sản xuất toàn bộ model 3D.

---

## B. Weaknesses — Điểm yếu

### 1. Phạm vi dự án đang quá rộng so với mục tiêu MVP

Project hiện có:

- Lobby tương tác.
- Bàn cờ.
- Nhiều loại board game.
- Hệ thống vật phẩm.
- Tiền, máu, trang bị.
- Vũ khí.
- Nhiều minigame.
- Chat.
- Có định hướng voice.
- Nhiều loại object vật lý.
- Hệ thống tuỳ chỉnh bàn chơi.

Với quy mô hiện tại, rủi ro lớn nhất là **nhiều tính năng ở trạng thái “đã bắt đầu” nhưng chưa có trải nghiệm hoàn thiện**.

Đặc biệt, `ROADMAP.md` cho biết tài liệu đang trong quá trình thiết kế lại và một số phần roadmap cũ chưa còn khớp với hướng mới.

### 2. Các quyết định gameplay cốt lõi vẫn chưa được chốt hoàn toàn

Roadmap vẫn còn các câu hỏi quan trọng như:

- Điều kiện thắng cuối cùng của bàn cờ.
- Loại ô sự kiện.
- Thời lượng một ván.
- Danh sách minigame chính thức.
- Tên sản phẩm cuối cùng.
- Cách sử dụng một số vật phẩm và quân cờ.

Đây không phải các chi tiết nhỏ. Chúng ảnh hưởng trực tiếp đến:

- Cấu trúc bàn cờ.
- Cân bằng kinh tế.
- UI.
- Độ dài trận đấu.
- Thứ tự phát triển.
- Cách thiết kế minigame.

Nếu tiếp tục code trước khi chốt các quyết định này, khả năng phải sửa lại hệ thống là cao.

### 3. Tính nhất quán multiplayer vẫn còn rủi ro

`M﻿INIGAME.md` ghi nhận Tank Battle từng tạo ra ranking khác nhau giữa master và client khác:

- Master: `[2,6,3,1,5,4]`
- Máy khác: `[1,2,3,4,5,6]`

Dù hiện tại bảng xếp hạng từ master được phát đi nên chưa phá hỏng toàn bộ flow, đây vẫn là dấu hiệu nguy hiểm vì ranking là dữ liệu ảnh hưởng đến lượt chơi tiếp theo.

Các hệ thống nhạy cảm cần tiếp tục được kiểm chứng:

- Ranking.
- Kết quả va chạm.
- Vật lý.
- Thời gian.
- Quyền sở hữu object.
- Rejoin và disconnect.
- Chuyển master.

### 4. Shared Authority không phù hợp cho cạnh tranh nghiêm túc

Kiến trúc Shared Authority giúp giảm chi phí server và phù hợp cho game bạn bè, nhưng không chống gian lận tốt.

Người chơi có thể có lợi thế nếu:

- Can thiệp client.
- Gửi input không hợp lệ.
- Làm sai lệch logic cục bộ.
- Lạm dụng quyền sở hữu object.
- Dùng bản build đã chỉnh sửa.

Điểm này đã được ghi nhận trong phần giới hạn của `readme.md`. Vì vậy PartyBash phù hợp hơn với nhóm bạn hoặc đồ án, không nên định vị sớm như một game competitive online.

### 5. Tài sản đồ họa và âm thanh chưa đồng đều

Project vẫn còn:

- Placeholder geometry.
- Một số model chưa xác định rõ license.
- Âm thanh FLAC cần chuyển đổi.
- Một số asset còn thiếu.
- Animation và art direction chưa hoàn thiện hoàn toàn.
- Một số vật thể cần tự dựng hoặc thay thế.

Điều này có thể khiến trải nghiệm giữa các khu vực không nhất quán, dù gameplay framework đã khá lớn.

### 6. Tài liệu nhiều nhưng khó duy trì đồng bộ

`ROADMAP.md` rất chi tiết, nhưng dài và chứa cả:

- Quyết định hiện tại.
- Lịch sử lỗi.
- Thiết kế cũ.
- Ghi chú kiểm thử.
- Các vấn đề đã giải quyết.
- Các vấn đề còn mở.

Ưu điểm là giữ được nhiều kiến thức; nhược điểm là người mới có thể khó phân biệt:

- Cái gì đã hoàn thành.
- Cái gì đang làm.
- Cái gì đã bị loại.
- Cái gì là quyết định chính thức.

### 7. License sản phẩm và một số asset chưa hoàn chỉnh

Project chưa có project-wide license. Ngoài ra, `CREDITS.md` vẫn liệt kê một số model chưa rõ license hoàn toàn.

Điều này không cản trở prototype nội bộ, nhưng sẽ trở thành vấn đề nếu muốn:

- Public repository.
- Phát hành build.
- Đăng lên itch.io hoặc nền tảng khác.
- Cho người khác redistribute project.

---

## C. Opportunities — Cơ hội

### 1. Tập trung vào một vertical slice rất dễ trình diễn

PartyBash có thể tạo một bản MVP mạnh với phạm vi:

- 2–4 người.
- Một lobby nhỏ.
- Một bàn cờ duy nhất.
- Một điều kiện thắng rõ ràng.
- 2–3 loại ô sự kiện.
- Một minigame hoàn chỉnh.
- Chat text.
- Một vòng chơi kéo dài khoảng 10–15 phút.

Bản này đủ để chứng minh:

- Multiplayer hoạt động.
- Gameplay loop hoàn chỉnh.
- Minigame kết nối được với bàn cờ.
- Người chơi có thể chơi từ đầu đến cuối.

Đây sẽ có giá trị hơn việc tiếp tục thêm nhiều trò nhưng chưa có một trận đấu hoàn chỉnh, ổn định.

### 2. Biến framework thành lợi thế dài hạn

Nếu framework `MiniGame`, `MiniGame3D`, `MiniGameLan` và hệ thống ranking được ổn định, project có thể mở rộng nội dung khá nhanh.

Có thể thiết kế nhiều game theo một số khuôn:

- Đua về đích.
- Sinh tồn.
- Thu thập vật phẩm.
- Né chướng ngại vật.
- Đấu đối kháng.
- Tính điểm theo thời gian.
- Phản xạ hoặc timing.

Điều này giúp giảm chi phí phát triển từng minigame mới.

### 3. Tận dụng tính xã hội của lobby

Lobby có thể trở thành USP của PartyBash nếu được thiết kế tốt:

- Người chơi gặp nhau trước trận.
- Có thể chơi các trò phụ không cạnh tranh.
- Có thể xem người khác chơi.
- Có thể tương tác với đồ vật và bàn game.
- Có chat và biểu cảm.
- Có khu vực riêng cho từng hoạt động.

Đây là hướng khác biệt so với menu lobby thông thường.

### 4. Phù hợp cho đồ án và portfolio kỹ thuật

Project thể hiện được nhiều kỹ năng:

- Multiplayer networking.
- Replication.
- RPC.
- Scene architecture.
- 3D interaction.
- Game-state management.
- Minigame framework.
- Asset pipeline.
- Debugging trên nhiều client.

Vì vậy, ngay cả khi chưa trở thành game thương mại, PartyBash vẫn có thể là một portfolio project mạnh nếu có một bản demo hoàn chỉnh và video gameplay rõ ràng.

### 5. Cơ hội xây dựng quy trình playtest có dữ liệu

`GAMEPLAY_BALANCE_PLAN.md` đã có hướng đo:

- Thời lượng trận.
- Vàng kiếm được.
- Chênh lệch giữa người chơi.
- Số lần mở rương.
- Tỷ lệ bắn trúng.
- Số lần chết.
- Số vòng chơi.

Nếu biến các chỉ số này thành bảng playtest chính thức, nhóm có thể cân bằng dựa trên dữ liệu thay vì cảm nhận.

### 6. Có thể mở rộng theo hướng private party thay vì competitive

Thay vì cạnh tranh với các game online lớn, PartyBash nên tập trung vào:

- Chơi cùng bạn bè.
- Trận ngắn.
- Hài hước và hỗn loạn.
- Tương tác vật lý.
- Lobby có thể khám phá.
- Không yêu cầu matchmaking chuyên nghiệp.

Đây là phân khúc phù hợp hơn với Shared Authority và hạ tầng Photon Cloud hiện tại.

---

## D. Threats — Rủi ro / Đe dọa

### 1. Phụ thuộc vào Photon Fusion bản preview

Project đang dùng Photon Fusion Godot 3 Preview 555. SDK preview có thể gây rủi ro về:

- API thay đổi.
- Bug chưa ổn định.
- Tài liệu hạn chế.
- Khó nâng cấp.
- Khó tìm giải pháp cộng đồng.

Nếu SDK thay đổi hoặc không còn tương thích với Godot phiên bản mới, chi phí bảo trì sẽ tăng đáng kể.

### 2. Giới hạn Photon Cloud free tier

`CREDITS.md` ghi rõ đang dùng Photon Cloud free tier với giới hạn 20 CCU.

Điều này đủ cho demo nhỏ, nhưng không đủ cho:

- Test nhiều nhóm đồng thời.
- Public playtest lớn.
- Phát hành miễn phí với lượng người chơi đáng kể.
- Duy trì nhiều phòng lâu dài.

### 3. App ID nằm trong build có thể bị lạm dụng

App ID không phải secret tuyệt đối, nhưng nếu build được phát hành công khai, người khác có thể lấy App ID và sử dụng quota Photon của project.

Roadmap đã cảnh báo nguy cơ này. Vì vậy cần:

- Giữ repo private trong giai đoạn hiện tại.
- Không public build thử nghiệm không kiểm soát.
- Theo dõi quota Photon.
- Tách app ID test và app ID phát hành.

### 4. Rủi ro “feature creep” và không hoàn thành bản chơi được

Đây là rủi ro lớn nhất về quản lý dự án.

Mỗi tính năng riêng lẻ có vẻ nhỏ, nhưng tổng cộng tạo thành một sản phẩm rất lớn:

- Nhiều lobby object.
- Nhiều minigame.
- Nhiều loại board.
- Nhiều loại item.
- Vật lý.
- UI.
- Audio.
- Multiplayer.
- Cân bằng.
- Art polish.

Nếu không đóng băng phạm vi, project có thể tiếp tục phát triển về chiều rộng nhưng không đạt trạng thái “một trận hoàn chỉnh, ổn định và vui”.

### 5. Multiplayer bug khó tái hiện

Các lỗi liên quan đến:

- Timing.
- RTT.
- Master migration.
- Late join.
- Object ownership.
- Physics.
- Disconnect.
- Nhiều client dùng các build khác nhau.

có thể không xuất hiện trong test một máy. Khi số người chơi tăng, lỗi đồng bộ sẽ khó chẩn đoán hơn.

### 6. Rủi ro license khi phát hành

Một số asset được ghi là CC-BY hoặc chưa rõ license. Nếu không hoàn tất kiểm tra và attribution, project có thể gặp vấn đề khi phát hành công khai hoặc thương mại hóa.

### 7. Cạnh tranh với các game party đã có thương hiệu mạnh

Ý tưởng party board game và minigame có nhiều đối thủ nổi bật. PartyBash khó cạnh tranh bằng số lượng nội dung hoặc độ hoàn thiện.

Lợi thế nên đến từ:

- Lobby 3D tương tác.
- Cảm giác vật lý.
- Không khí hài hước.
- Minigame có bản sắc riêng.
- Dễ chơi cùng nhóm bạn.
- Một gameplay loop ngắn và ổn định.

---

# 3. Đánh giá chiến lược

## Kết luận ngắn

| Hạng mục | Đánh giá |
|---|---|
| Ý tưởng | Tốt, dễ hiểu, có bản sắc |
| Nền tảng kỹ thuật | Mạnh đối với prototype/đồ án |
| Multiplayer | Có nền tảng rõ nhưng còn cần kiểm chứng sâu |
| Nội dung | Phong phú nhưng có dấu hiệu quá tải phạm vi |
| Trạng thái sản phẩm | Chưa nên mở rộng thêm trước khi hoàn thiện MVP |
| Khả năng demo | Cao nếu cắt phạm vi đúng |
| Khả năng phát hành công khai | Chưa sẵn sàng do license, ổn định mạng và giới hạn Photon |
| Hướng phù hợp | Private party game / portfolio / đồ án multiplayer |

---

# 4. Khuyến nghị ưu tiên

## Ưu tiên 1 — Chốt một MVP có thể chơi từ đầu đến cuối

Nên chốt ngay:

1. Điều kiện thắng.
2. Độ dài trận.
3. Số người chơi mục tiêu.
4. Một layout bàn cờ.
5. Hai hoặc ba loại ô.
6. Một minigame bắt buộc.
7. Một màn hình kết thúc trận.

Mục tiêu: một nhóm 2–4 người có thể chơi trọn một trận mà không cần dùng tính năng chưa hoàn thiện.

## Ưu tiên 2 — Sửa triệt để tính deterministic của minigame

Trước khi thêm game mới, cần kiểm tra:

- Cùng seed có cho cùng kết quả không.
- Ranking trên mọi client có giống nhau không.
- Master có phải nguồn quyết định duy nhất cho kết quả quan trọng không.
- Kết quả va chạm và timer có bị lệch không.
- Khi một client disconnect thì trận có kết thúc đúng không.

Tank Battle nên được dùng như test case đại diện.

## Ưu tiên 3 — Đóng băng scope nội dung

Tạm thời không nên thêm nhiều lobby object hoặc minigame mới cho đến khi:

- Lobby hiện tại ổn định.
- Một vòng board game hoàn chỉnh.
- Một minigame hoạt động ổn định với ít nhất 2–4 client.
- Có playtest thực tế.

## Ưu tiên 4 — Làm một vòng playtest có số liệu

Dùng các chỉ số trong `GAMEPLAY_BALANCE_PLAN.md`:

- Thời lượng trận.
- Tỷ lệ người chơi bỏ cuộc.
- Thời điểm người chơi đầu tiên đạt mốc tài nguyên.
- Chênh lệch giữa người đứng đầu và cuối.
- Tần suất sử dụng item.
- Tỷ lệ hoàn thành minigame.
- Số lỗi mạng trong mỗi trận.

## Ưu tiên 5 — Hoàn thiện phát hành nội bộ

Trước khi public build:

- Hoàn tất license và attribution.
- Chuyển asset âm thanh chưa tương thích.
- Tách App ID test khỏi cấu hình phát hành.
- Dọn file tạm và build artifact.
- Viết hướng dẫn chạy ngắn gọn.
- Dùng cùng một version build cho toàn bộ người chơi.
- Xác nhận build chạy được trên máy không cài Godot.

---

# 5. Chiến lược SO / WO / ST / WT

### SO — Dùng điểm mạnh để tận dụng cơ hội

- Dùng framework minigame hiện có để tạo một vertical slice hoàn chỉnh.
- Dùng lobby 3D làm điểm khác biệt thay vì cạnh tranh bằng số lượng minigame.
- Dùng tài liệu networking làm lợi thế cho portfolio và đồ án.
- Dùng asset miễn phí để nhanh chóng tập trung vào gameplay và playtest.

### WO — Dùng cơ hội để khắc phục điểm yếu

- Thu hẹp MVP để giải quyết feature creep.
- Dùng playtest có số liệu để chốt gameplay còn bỏ ngỏ.
- Dùng một minigame chuẩn để kiểm tra và sửa deterministic ranking.
- Tách tài liệu “trạng thái hiện tại” khỏi lịch sử trong roadmap.

### ST — Dùng điểm mạnh để giảm rủi ro

- Tận dụng master-authority cho các kết quả quan trọng.
- Dùng replicated state thay vì dựa vào state cục bộ.
- Giữ game theo hướng private party để phù hợp giới hạn Shared Authority.
- Dùng hệ thống credits hiện có để giảm rủi ro license.

### WT — Giảm điểm yếu và tránh rủi ro

- Không public build khi App ID và license chưa được xử lý.
- Không thêm hệ thống voice trước khi core multiplayer ổn định.
- Không phát triển thêm minigame nếu chưa có một trận hoàn chỉnh.
- Không mở rộng số người chơi trước khi kiểm thử ổn định ở quy mô mục tiêu.
- Không định vị game là competitive cho đến khi có server-authoritative backend.

---

## Kết luận

PartyBash có **nền tảng kỹ thuật và ý tưởng tốt**, đặc biệt ở kiến trúc multiplayer, lobby 3D và framework minigame. Điểm yếu lớn nhất không phải thiếu tính năng mà là **phạm vi đang quá rộng và một số quyết định gameplay cốt lõi chưa được đóng băng**.

Chiến lược phù hợp nhất hiện tại là:

> **Hoàn thiện một bản MVP nhỏ nhưng chơi trọn vẹn, ổn định và vui trước; sau đó mới mở rộng số lượng minigame, vật phẩm và nội dung lobby.**

Nếu làm được điều này, PartyBash có tiềm năng trở thành một đồ án multiplayer nổi bật và một prototype party game có bản sắc riêng.