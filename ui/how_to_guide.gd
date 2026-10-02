class_name HowToGuide
extends ColorRect

## Tài liệu người chơi trong menu chính. Mỗi mục là một trang độc lập; danh mục bên trái
## giúp mở thẳng trang cần đọc thay vì phải cuộn qua một bài hướng dẫn dài.

signal close_requested

const ACCENT := "#8fe7d4"
const PAGES := [
	{
		"title": "01 · Mục tiêu ván chơi",
		"body": "[color=%s][b]MỤC TIÊU[/b][/color]\n" % ACCENT
				+ "Tích đủ vàng, tìm rương thật và trả phí mở rương để thắng ngay lập tức.\n\n"
				+ "[b]Một vòng chơi[/b]\n"
				+ "1. Tất cả người chơi bắt đầu trên cùng một ô.\n"
				+ "2. Thứ tự lượt đầu tiên được xáo ngẫu nhiên.\n"
				+ "3. Mỗi người tung xúc xắc và đi đúng số bước.\n"
				+ "4. Khi mọi người đã đi một lượt, cả phòng chơi một minigame ngẫu nhiên.\n"
				+ "5. Xếp hạng minigame trở thành thứ tự lượt của vòng tiếp theo.\n\n"
				+ "Các giá trị vàng, máu, thuế và checkpoint có thể được chủ phòng thay đổi trước khi vào sảnh."
	},
	{
		"title": "02 · Toàn bộ phím chung",
		"body": "[color=%s][b]DI CHUYỂN VÀ TƯƠNG TÁC[/b][/color]\n" % ACCENT
				+ "[b]W A S D[/b] — di chuyển\n"
				+ "[b]Chuột[/b] — xoay góc nhìn\n"
				+ "[b]Space[/b] — nhảy; nhân vật có thể nhảy hai lần\n"
				+ "[b]E[/b] — tương tác, nhặt vật; giữ rồi thả E để ném vật đang cầm\n"
				+ "[b]Q[/b] — đặt vật xuống hoặc đứng dậy khỏi ghế\n"
				+ "[b]F[/b] — đánh tay không trong minigame có cho phép đánh\n"
				+ "[b]M[/b] — đổi mẫu nhân vật khi đang ở sảnh\n\n"
				+ "[color=%s][b]GIAO DIỆN[/b][/color]\n" % ACCENT
				+ "[b]Enter[/b] — mở chat; Enter lần nữa để gửi\n"
				+ "[b]Esc[/b] — huỷ chat hoặc mở/đóng menu tạm dừng\n"
				+ "[b]Chuột trái[/b] — bắn khi đang có Súng một phát\n\n"
				+ "Mỗi minigame có phím riêng được ghi ở trang của trò đó."
	},
	{
		"title": "03 · Bàn party và lượt đi",
		"body": "[color=%s][b]TRONG LƯỢT CỦA BẠN[/b][/color]\n" % ACCENT
				+ "[b]Space hoặc E[/b] — tung xúc xắc.\n"
				+ "Nếu có nhiều đường đi: [b]A / D[/b] đổi lộ trình, [b]Space hoặc E[/b] xác nhận.\n\n"
				+ "Người chơi đi từng ô theo số xúc xắc rồi mới nhận hiệu ứng của ô dừng chân. "
				+ "Không thể dùng WASD để tự ý đi trên bàn.\n\n"
				+ "Sau khi tất cả người chơi đã đi đúng một lượt, bàn tạm dừng và một minigame ngẫu nhiên bắt đầu."
	},
	{
		"title": "04 · Ô Đất",
		"body": "[color=%s][b]CHIẾM ĐẤT[/b][/color]\n" % ACCENT
				+ "Ô đất chưa có chủ mang trạng thái unmarked. Người đầu tiên dừng trên ô sẽ đánh dấu ô bằng tên mình và chọn loại thuế.\n\n"
				+ "[b]1 — Thuế đất[/b]: lấy một ô đất của khách. Nếu khách không có đất, tự đổi thành thuế tiền.\n"
				+ "[b]2 — Thuế máu[/b]: lấy máu của khách và hồi lượng máu thực lấy được cho chủ đất.\n"
				+ "[b]3 — Thuế tiền[/b]: chuyển vàng từ khách sang chủ đất.\n"
				+ "[b]4 — Thuế trang bị[/b]: lấy món đầu tiên trong túi khách. Nếu khách không có đồ, tự đổi thành thuế tiền.\n\n"
				+ "Không chọn trong 12 giây thì ô mặc định dùng thuế tiền. Chủ đất trở lại đất của mình không phải trả thuế."
	},
	{
		"title": "05 · Ô Máu",
		"body": "[color=%s][b]HỒI MÁU[/b][/color]\n" % ACCENT
				+ "Dừng trên ô Máu để hồi máu ngay lập tức, tối đa bằng giới hạn máu của phòng.\n\n"
				+ "Thiết lập mặc định: hồi [b]3 máu[/b], tối đa [b]10 máu[/b]. Chủ phòng có thể đổi cả hai con số trước khi mở sảnh.\n\n"
				+ "Nếu máu đã đầy, ô không cộng thêm và bảng sự kiện sẽ báo máu đã đầy."
	},
	{
		"title": "06 · Ô Tiền",
		"body": "[color=%s][b]NHẬN VÀNG[/b][/color]\n" % ACCENT
				+ "Dừng trên ô Tiền để nhận vàng ngay lập tức.\n\n"
				+ "Thiết lập mặc định: [b]+15 vàng[/b]. Chủ phòng có thể đổi số vàng nhận được.\n\n"
				+ "Vàng dùng để mở rương. Thuế tiền và việc mở rương giả có thể làm giảm số vàng đang giữ."
	},
	{
		"title": "07 · Ô Trang bị",
		"body": "[color=%s][b]NHẬN TRANG BỊ[/b][/color]\n" % ACCENT
				+ "Dừng trên ô Trang bị sẽ tự nhận ngẫu nhiên một món: khoảng 1/3 là Khiên và 2/3 là Súng một phát. Không cần click vào ô để nhặt.\n\n"
				+ "[b]Khiên[/b] — bị động, tự chặn trọn một lần mất máu rồi biến mất. Chuột trái không dùng Khiên.\n\n"
				+ "[b]Súng một phát[/b] — ngắm bằng tâm màn hình và bấm chuột trái. Tầm 18 m, gây 3 sát thương. Bắn trúng hay trượt đều tiêu súng.\n\n"
				+ "Có thể bắn khi bàn đang đứng yên; không thể bắn trong lúc quân đang di chuyển, đang chọn đường hoặc khi minigame đang phủ lên bàn."
	},
	{
		"title": "08 · Rương và hồi sinh",
		"body": "[color=%s][b]BỐN RƯƠNG[/b][/color]\n" % ACCENT
				+ "Mỗi ván có 4 rương xuất hiện ngẫu nhiên: [b]1 rương thật[/b] và [b]3 rương giả[/b]. "
				+ "Dừng trên rương để thử mở; không đủ vàng thì rương vẫn còn nguyên.\n\n"
				+ "Giá mặc định là [b]100 vàng[/b]. Rương giả vẫn thu đủ phí và biến mất. Mở đúng rương thật sẽ thắng ván.\n\n"
				+ "[color=%s][b]CHECKPOINT[/b][/color]\n" % ACCENT
				+ "Sau một số bước nhất định, game mở điểm hồi sinh cá nhân ở ô cạnh đường đi. Mặc định là mỗi 18 bước.\n"
				+ "Khi hết máu, bạn hồi đầy máu tại checkpoint gần nhất; vàng và trang bị được giữ lại."
	},
	{
		"title": "09 · Minigame và phần thưởng",
		"body": "[color=%s][b]KHI NÀO MINIGAME BẮT ĐẦU?[/b][/color]\n" % ACCENT
				+ "Sau khi toàn bộ người chơi đã tung xúc xắc xong một vòng, game chọn ngẫu nhiên một trong 11 minigame đang hoạt động.\n\n"
				+ "[b]Xếp hạng có hai tác dụng[/b]\n"
				+ "• Hạng 1 nhận Súng một phát.\n"
				+ "• Các hạng sau nhận vàng giảm dần theo thứ hạng.\n"
				+ "• Thứ tự xếp hạng trở thành thứ tự lượt của vòng bàn tiếp theo.\n\n"
				+ "Mỗi trò có màn đếm ngược 3 giây. Luật và phím chi tiết nằm ở từng trang minigame bên dưới."
	},
	{
		"title": "10 · Tank 1990",
		"body": "[color=%s][b]PHÍM[/b][/color]\n[b]W A S D[/b] lái xe theo 4 hướng · [b]J hoặc Space[/b] bắn.\n\n" % ACCENT
				+ "[color=%s][b]LUẬT[/b][/color]\n" % ACCENT
				+ "Đạn trúng là bị loại ngay, không có máu và không hồi sinh. Tường gạch có thể bị phá để mở đường. "
				+ "Ván kéo dài tối đa 75 giây hoặc kết thúc khi còn một xe.\n\n"
				+ "[b]Xếp hạng:[/b] sống sót lâu hơn đứng trên; người sống cuối cùng đứng hạng nhất."
	},
	{
		"title": "11 · Breaking Blocks",
		"body": "[color=%s][b]PHÍM[/b][/color]\n[b]W A S D[/b] chạy · [b]Space[/b] nhảy.\n\n" % ACCENT
				+ "[color=%s][b]LUẬT[/b][/color]\n" % ACCENT
				+ "Đứng trên một ô quá lâu làm ô nứt rồi vỡ. Vết nứt được giữ lại khi bạn rời ô, vì vậy phải liên tục chọn đường an toàn và nhảy qua khe.\n\n"
				+ "Rơi khỏi sàn sẽ bị loại. [b]Xếp hạng:[/b] sống sót lâu hơn đứng trên."
	},
	{
		"title": "12 · Laser Leap",
		"body": "[color=%s][b]PHÍM[/b][/color]\n[b]W A S D[/b] chạy · [b]Space[/b] nhảy.\n\n" % ACCENT
				+ "[color=%s][b]LUẬT[/b][/color]\n" % ACCENT
				+ "Nhảy qua các tia laser đang quét sàn. Tia đổi hướng, tốc độ và tâm quay theo từng đợt nên không thể chỉ học một nhịp cố định.\n\n"
				+ "Chạm tia hoặc rơi khỏi sàn sẽ bị loại. Ván tối đa 90 giây. [b]Xếp hạng:[/b] sống sót lâu hơn đứng trên."
	},
	{
		"title": "13 · Searing Spotlights",
		"body": "[color=%s][b]PHÍM[/b][/color]\n[b]W A S D[/b] chạy.\n\n" % ACCENT
				+ "[color=%s][b]LUẬT[/b][/color]\n" % ACCENT
				+ "Khi sân còn sáng, ghi nhớ vị trí và đường quét của đèn. Khi tối, tránh các vùng sáng đang di chuyển; đứng trong vùng sáng làm mất máu.\n\n"
				+ "Viền sân là tường vô hình nên không chết vì chạy khỏi mép. Ván kéo dài 75 giây. [b]Xếp hạng:[/b] sống sót lâu hơn đứng trên."
	},
	{
		"title": "14 · Magma & Mages",
		"body": "[color=%s][b]PHÍM[/b][/color]\n[b]W A S D[/b] chạy · [b]E[/b] bắn cầu lửa.\n\n" % ACCENT
				+ "[color=%s][b]LUẬT[/b][/color]\n" % ACCENT
				+ "Cầu lửa gây sát thương và hất đối thủ. Các vành đỏ là cảnh báo khu vực sắp biến thành nham thạch; hãy rời khỏi đó hoặc hất người khác vào.\n\n"
				+ "Hết máu hoặc rơi khỏi sân sẽ bị loại. Ván kéo dài 75 giây. [b]Xếp hạng:[/b] sống sót lâu hơn đứng trên."
	},
	{
		"title": "15 · Explosive Exchange",
		"body": "[color=%s][b]PHÍM[/b][/color]\n[b]W A S D[/b] chạy · [b]E[/b] chuyền bom.\n\n" % ACCENT
				+ "[color=%s][b]LUẬT[/b][/color]\n" % ACCENT
				+ "Người đang ôm bom phải chạy tới gần một người trong vòng đỏ rồi bấm E để chuyền. Có hồi chiêu ngắn nên bom không thể nảy qua lại ngay lập tức.\n\n"
				+ "Ai giữ bom lúc đồng hồ nổ sẽ bị loại; thời gian bom ngắn dần sau mỗi vụ nổ. [b]Xếp hạng:[/b] thứ tự sống sót, người cuối cùng thắng."
	},
	{
		"title": "16 · Crown Capture",
		"body": "[color=%s][b]PHÍM[/b][/color]\n[b]W A S D[/b] chạy · [b]F[/b] đánh.\n\n" % ACCENT
				+ "[color=%s][b]LUẬT[/b][/color]\n" % ACCENT
				+ "Chạy vào vòng của vương miện để nhặt. Đánh trúng người đang đội miện làm miện rơi đúng tại chỗ bị đánh; sau một khoảng nghỉ ngắn mới nhặt lại được.\n\n"
				+ "Không ai bị loại trong trò này. Ván kéo dài 60 giây. [b]Xếp hạng:[/b] tổng số giây đã đội vương miện."
	},
	{
		"title": "17 · Temporal Trails",
		"body": "[color=%s][b]PHÍM[/b][/color]\n[b]W A S D[/b] chạy.\n\n" % ACCENT
				+ "[color=%s][b]LUẬT[/b][/color]\n" % ACCENT
				+ "Mỗi vòng, hãy ghi nhớ hình của vệt sáng mang màu của bạn. Khi vệt tắt, đi lại đúng con đường đó từ đầu tới cuối. Đi lệch khỏi vệt sẽ mất máu.\n\n"
				+ "Ván kết thúc sau vòng cuối hoặc khi người chơi hết máu/rơi khỏi sân. [b]Xếp hạng:[/b] tổng tỷ lệ các vệt đã hoàn thành; bằng nhau thì người sống lâu hơn đứng trên."
	},
	{
		"title": "18 · Word Wars",
		"body": "[color=%s][b]PHÍM[/b][/color]\n[b]W A S D[/b] chạy · [b]E[/b] nhập chữ · [b]F[/b] đánh.\n\n" % ACCENT
				+ "[color=%s][b]LUẬT[/b][/color]\n" % ACCENT
				+ "Đọc từ tiếng Anh trên đầu mình, lần lượt chạy tới ô mang chữ cái cần thiết rồi bấm E. Đúng hết từ sẽ ghi một điểm và nhận từ mới.\n\n"
				+ "Bị đánh sẽ bị hất và choáng ngắn, nhưng không mất tiến độ từ. Ván kéo dài 60 giây. [b]Xếp hạng:[/b] số từ hoàn thành; hoà thì ai đã tiến xa hơn trong từ hiện tại đứng trên."
	},
	{
		"title": "19 · Sidestep Slope",
		"body": "[color=%s][b]PHÍM[/b][/color]\n[b]W A S D[/b] chạy · [b]Chuột[/b] xoay hướng.\n\n" % ACCENT
				+ "[color=%s][b]LUẬT[/b][/color]\n" % ACCENT
				+ "Chạy lên dốc trong làn của mình và né các tảng đá lăn xuống. Trúng đá sẽ bị loại ngay.\n\n"
				+ "Ván kéo dài 30 giây. [b]Xếp hạng:[/b] quãng đường xa nhất đã đạt được, không bị trừ nếu bị hất lùi."
	},
	{
		"title": "20 · Slippery Sprint",
		"body": "[color=%s][b]PHÍM[/b][/color]\n[b]W A S D[/b] chạy · [b]Chuột[/b] xoay hướng.\n\n" % ACCENT
				+ "[color=%s][b]LUẬT[/b][/color]\n" % ACCENT
				+ "Chạy trên đường băng trơn tới vạch đỏ. Nhân vật tăng tốc và dừng chậm hơn bình thường, vì vậy cần chỉnh hướng sớm.\n\n"
				+ "Ván kéo dài 30 giây. [b]Xếp hạng:[/b] người về đích đứng trên và xếp theo thời gian về; người chưa về xếp theo quãng đường xa nhất."
	},
]

@onready var _page_list: ItemList = %HowToPageList
@onready var _page_title: Label = %HowToPageTitle
@onready var _page_body: RichTextLabel = %HowToPageBody
@onready var _counter: Label = %HowToPageCounter
@onready var _previous: Button = %HowToPrevBtn
@onready var _next: Button = %HowToNextBtn
@onready var _close: Button = %HowToCloseBtn

var _current := 0


func _ready() -> void:
	for page in PAGES:
		_page_list.add_item(str(page["title"]))
	_page_list.item_selected.connect(_set_page)
	_previous.pressed.connect(func(): _set_page(_current - 1))
	_next.pressed.connect(func(): _set_page(_current + 1))
	_close.pressed.connect(func(): close_requested.emit())
	_set_page(0)


func open() -> void:
	visible = true
	_set_page(0)
	_page_list.grab_focus()


func close() -> void:
	visible = false


func _set_page(index: int) -> void:
	_current = clampi(index, 0, PAGES.size() - 1)
	var page: Dictionary = PAGES[_current]
	_page_list.select(_current)
	_page_list.ensure_current_is_visible()
	_page_title.text = str(page["title"])
	_page_body.text = str(page["body"])
	_page_body.scroll_to_line(0)
	_counter.text = "%d / %d" % [_current + 1, PAGES.size()]
	_previous.disabled = _current == 0
	_next.disabled = _current == PAGES.size() - 1
