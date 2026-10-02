1. Magma & Mages
Luật: Pháp sư đứng sàn góc nhìn trên cao, bắn cầu lửa đẩy/hạ đối thủ. Chết thứ i nhận n-i điểm. Mỗi cú bắn gửi 1 gói tin.
Node Godot: Node3D (Root) -> Camera3D, DirectionalLight3D, WorldEnvironment, StaticBody3D (Sàn/Dung nham: MeshInstance3D, CollisionShape3D), Node3D (Spawner), CharacterBody3D (Player: MeshInstance3D, CollisionShape3D, Marker3D), Area3D (Cầu lửa: MeshInstance3D, CollisionShape3D, GPUParticles3D), CanvasLayer (UI: Control, Label).

2. Snowy Spin — ĐÃ XOÁ khỏi trò (giữ lại đây làm bản ghi kế hoạch)
Luật: 3 vòng x 20s trên sàn trượt. Thanh chướng ngại vật xoay liên tục. Điểm loại trừ n-i mỗi vòng. Gửi 1 gói tin/đòn + 1 gói tin/vòng.
Node Godot: Node3D (Root) -> Camera3D, Timer (20s), AnimatableBody3D (Thanh xoay: MeshInstance3D, CollisionShape3D), StaticBody3D (Sàn tuyết: MeshInstance3D, CollisionShape3D), CharacterBody3D (Player: MeshInstance3D, CollisionShape3D), CanvasLayer (UI: Label).

3. Acidic Atoll
Luật: Đứng trên đảo nhỏ quanh biển axit. Bom rơi nổ sàn/hất văng, ngã xuống axit bị loại. Mỗi bom rơi gửi 1 gói tin.
Node Godot: Node3D (Root) -> Camera3D, StaticBody3D (Đảo: MeshInstance3D, CollisionShape3D), Area3D (Axit: MeshInstance3D, CollisionShape3D), RigidBody3D (Bom: MeshInstance3D, CollisionShape3D, Area3D nổ), CharacterBody3D (Player: MeshInstance3D, CollisionShape3D), CanvasLayer (UI).

4. Explosive Exchange
Luật: Chuyền bom đếm ngược. Giữ bom va chạm người khác để truyền. Nổ loại người giữ, điểm theo thứ tự nổ n-i. Master quản lý ai_om.
Node Godot: Node3D (Root) -> Camera3D, StaticBody3D (Sàn), CharacterBody3D (Player: MeshInstance3D, CollisionShape3D, Area3D va chạm, Marker3D vị trí bom), Node3D (Bom: MeshInstance3D, GPUParticles3D, Timer), CanvasLayer (UI).

5. Crown Capture
Luật: Cướp giữ vương miện trong 60s. Cứ 1 giây giữ được 1 điểm. Master tính toán ai_giu.
Node Godot: Node3D (Root) -> Camera3D, Timer (60s & 1s), Area3D (Vương miện: MeshInstance3D, CollisionShape3D), CharacterBody3D (Player: MeshInstance3D, CollisionShape3D, Area3D cướp, Marker3D gắn vương miện), CanvasLayer (UI: ProgressBar, Label).

6. Breaking Blocks
Luật: Đứng trên gạch vỡ dần trong 60s, tính điểm theo thời gian sống. Chết chỉ gửi 1 gói tin "tôi chết".
Node Godot: Node3D (Root) -> Camera3D, Timer (60s), Node3D (Sàn gạch: các StaticBody3D gồm MeshInstance3D, CollisionShape3D, Area3D, Timer), CharacterBody3D (Player: MeshInstance3D, CollisionShape3D), CanvasLayer (UI).

7. Laser Leap
Luật: Nhảy né laser quét, không giới hạn giờ, tính điểm sống sót. Chết gửi 1 gói tin "tôi chết".
Node Godot: Node3D (Root) -> Camera3D, Node3D (Laser Rotator: Area3D gồm MeshInstance3D, CollisionShape3D, RayCast3D), CharacterBody3D (Player: MeshInstance3D, CollisionShape3D), CanvasLayer (UI).

8. Searing Spotlights
Luật: Tối hoàn toàn, đèn chiếu ngẫu nhiên. 100 máu, đứng trong đèn -40 máu/giây. Chết gửi 1 gói tin "tôi chết".
Node Godot: Node3D (Root) -> WorldEnvironment, Camera3D, Node3D (Đèn: SpotLight3D, Area3D, AnimationPlayer), CharacterBody3D (Player: MeshInstance3D, CollisionShape3D), CanvasLayer (UI: ProgressBar).

9. Slippery Sprint
Luật: Chạy đua trên băng, camera sau lưng riêng. Thứ hạng về đích hoặc đo quãng đường Z. Chết gửi 1 gói tin "tôi chết".
Node Godot: Node3D (Root) -> StaticBody3D (Đường đua), Area3D (Vạch đích), CharacterBody3D (Player: Camera3D sau lưng, MeshInstance3D, CollisionShape3D), CanvasLayer (UI).

10. ~~Bounding Blocks~~ (đã xoá 2026-10-02)
Luật: Giậm ô đổi màu trong 60s. Hết giờ đếm ô. 0 gói tin mạng, tự suy từ vị trí.
Node Godot: Node3D (Root) -> Camera3D, Timer (60s), GridMap / mảng Area3D, CharacterBody3D (Player: MeshInstance3D, CollisionShape3D, RayCast3D bắn xuống), CanvasLayer (UI).

11. Temporal Trails
Luật: Di chuyển tạo vệt đuôi tường. Chạm vệt bị loại. 0 gói tin mạng, tự suy từ vị trí.
Node Godot: Node3D (Root) -> Camera3D, CharacterBody3D (Player: MeshInstance3D, CollisionShape3D), Node3D (Trail Manager: các StaticBody3D / Area3D gồm MeshInstance3D, CollisionShape3D), CanvasLayer (UI).

12. Word Wars
Luật: Đấm khối chữ cái rơi xuống ghép từ trong 60s. Tính điểm theo số từ. 1 gói tin/cú đấm.
Node Godot: Node3D (Root) -> Camera3D, Timer (60s), RigidBody3D (Chữ cái: MeshInstance3D, Label3D, CollisionShape3D), CharacterBody3D (Player: MeshInstance3D, CollisionShape3D, Area3D đấm, AnimationPlayer), CanvasLayer (UI: Label).

13. Sidestep Slope
Luật: Chạy né vật cản lăn dốc, camera sau lưng riêng. Tính điểm quãng đường. 0 gói tin mạng.
Node Godot: Node3D (Root) -> StaticBody3D (Mặt dốc), RigidBody3D (Vật cản), CharacterBody3D (Player: Camera3D, MeshInstance3D, CollisionShape3D), CanvasLayer (UI: Label).

14. Nhặt quà né rác
Luật: Chạy băng riêng 60s. Quà +1, quà to +3, rác -1 (cho âm). 0 gói tin mạng.
Node Godot: Node3D (Root) -> Timer (60s), CharacterBody3D (Player: Camera3D, MeshInstance3D, CollisionShape3D, Area3D nhặt), Area3D (Quà/Rác: MeshInstance3D, CollisionShape3D), CanvasLayer (UI: Label).

15. Fractured Faces
Luật: Ghép mảnh mặt góc nhìn trên cao khu riêng. Thứ hạng hoàn thành hoặc số mảnh đúng. 0 gói tin + 1 gói tin cuối.
Node Godot: Node3D (Root) -> Camera3D, Node3D (Khung ảnh & Marker3D/Area3D vị trí), Area3D (Mảnh ghép: MeshInstance3D, CollisionShape3D), CanvasLayer (UI: Label).

16. Đếm thú
Luật: Màn hình trên cao quan sát 3 loại thú, không render người chơi. 5 vòng đếm 1 loại thú. Đúng +1, sai 0. 0 gói tin + 1 gói tin/vòng.
Node Godot: Node3D (Root) -> Camera3D, Node3D (Spawner & NavigationRegion3D), CharacterBody3D (Thú NPC: MeshInstance3D, CollisionShape3D, NavigationAgent3D), CanvasLayer (UI: Label, LineEdit, Button).

17. Rockin Rhythm
Luật: Overlay 2D hàng ngang. Perfect +3, Good +1, Miss 0, Combo >= 10 x1.5. 1 gói tin/giây/người.
Node Godot: Control (Root 2D) -> AudioStreamPlayer, TextureRect (Thanh nốt), Area2D (Vạch căn: CollisionShape2D), Path2D + PathFollow2D (hoặc Node2D nốt: Area2D, Sprite2D), CanvasLayer (UI: Label).

18. Bóng chày
Luật: Overlay 2D hàng ngang, 15 quả ném. Tam +-40ms 3đ, +-100ms 2đ, +-180ms 1đ, trật 0đ. 1 gói tin cuối.
Node Godot: Control (Root 2D) -> AnimatedSprite2D (Cầu thủ), Node2D (Bóng: Sprite2D), AnimationPlayer, CanvasLayer (UI: Label).