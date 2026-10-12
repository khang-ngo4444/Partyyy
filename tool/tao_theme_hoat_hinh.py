"""Sinh ui/theme/cartoon_theme.tres — theme hoạt hình toàn cục.

Chạy: python tool/tao_theme_hoat_hinh.py  (từ gốc project)
Sửa màu / cỡ ở đây rồi chạy lại, đừng sửa tay file .tres.
"""
from pathlib import Path

# Bảng màu lấy từ map Rumble Reef.
MUC = "2B1B3D"       # mực: viền, chữ, bóng cứng
KEM = "FFF6DC"
KEM_DAM = "F3E3BC"
TRANG = "FFFFFF"
TROI = "4FC3F7"
CAM = "F58A2C"
HONG = "F78FA7"
VANG = "FFD54F"
TIM = "8E5CF7"
LA = "6CC04A"
DO = "EF4B4B"

WGHT = 2003265652  # TextServer.name_to_tag("wght")


def mau(hex_, a=1.0):
    r, g, b = (int(hex_[i:i + 2], 16) / 255 for i in (0, 2, 4))
    return f"Color({r:.4g}, {g:.4g}, {b:.4g}, {a:.4g})"


def sang(hex_, k):
    """k>0 sáng hơn, k<0 tối hơn."""
    c = [int(hex_[i:i + 2], 16) for i in (0, 2, 4)]
    if k >= 0:
        c = [round(v + (255 - v) * k) for v in c]
    else:
        c = [round(v * (1 + k)) for v in c]
    return "".join(f"{v:02X}" for v in c)


ext = []      # (id, type, path)
subs = []     # khối text sub_resource
props = []    # dòng thuộc tính theme


def ext_res(id_, type_, path):
    ext.append((id_, type_, path))
    return f'ExtResource("{id_}")'


def sub(id_, type_, **kv):
    lines = [f'[sub_resource type="{type_}" id="{id_}"]']
    for k, v in kv.items():
        lines.append(f"{k} = {v}")
    subs.append("\n".join(lines))
    return f'SubResource("{id_}")'


def hop(id_, bg, border=MUC, bw=4, r=20, bong=0, bong_mau=MUC, m=(18, 10, 18, 12),
        expand=0, center=True, border_a=1.0, bg_a=1.0, bong_a=1.0):
    kv = {
        "content_margin_left": f"{m[0]}.0", "content_margin_top": f"{m[1]}.0",
        "content_margin_right": f"{m[2]}.0", "content_margin_bottom": f"{m[3]}.0",
        "bg_color": mau(bg, bg_a),
    }
    if not center:
        kv["draw_center"] = "false"
    for s in ("left", "top", "right", "bottom"):
        kv[f"border_width_{s}"] = str(bw)
    kv["border_color"] = mau(border, border_a)
    for c in ("top_left", "top_right", "bottom_right", "bottom_left"):
        kv[f"corner_radius_{c}"] = str(r)
    if expand:
        for s in ("left", "top", "right", "bottom"):
            kv[f"expand_margin_{s}"] = f"{expand}.0"
    if bong:
        kv["shadow_color"] = mau(bong_mau, bong_a)
        kv["shadow_size"] = "1"
        kv["shadow_offset"] = f"Vector2(0, {bong})"
    kv["anti_aliasing_size"] = "1.2"
    return sub(id_, "StyleBoxFlat", **kv)


def p(key, val):
    props.append(f"{key} = {val}")


# ---------- Font ----------
nunito = ext_res("f_nunito", "FontFile", "res://ui/theme/fonts/Nunito.ttf")
baloo = ext_res("f_baloo", "FontFile", "res://ui/theme/fonts/Baloo2.ttf")
F_THAN = sub("F_than", "FontVariation", base_font=nunito,
             variation_opentype=f"{{\n{WGHT}: 800\n}}")
F_DAM = sub("F_dam", "FontVariation", base_font=nunito,
            variation_opentype=f"{{\n{WGHT}: 1000\n}}")
F_TIEU_DE = sub("F_tieu_de", "FontVariation", base_font=baloo,
                variation_opentype=f"{{\n{WGHT}: 800\n}}")

# ---------- Icon ----------
def icon(name):
    return ext_res(f"i_{name}", "Texture2D", f"res://ui/theme/{name}.svg")


I_KEO = icon("nam_keo")
I_KEO_SANG = icon("nam_keo_sang")
I_KEO_TAT = icon("nam_keo_tat")
I_BAT = icon("cong_tac_bat")
I_TAT = icon("cong_tac_tat")
I_TICH_BAT = icon("o_tich_bat")
I_TICH_TAT = icon("o_tich_tat")
I_XUONG = icon("mui_xuong")

# ---------- Mặc định ----------
p("default_font", F_THAN)
p("default_font_size", "22")

# ---------- Button + biến thể màu ----------
FOCUS = hop("Nut_focus", CAM, border=CAM, bw=6, r=26, expand=6, center=False, m=(0, 0, 0, 0))


def nut(ten, nen, chu=MUC, vien_chu=None):
    base = ten == "Button"
    pre = ten
    p(f"{pre}/styles/normal", hop(f"{ten}_normal", nen, bong=6, m=(20, 10, 20, 14)))
    p(f"{pre}/styles/hover", hop(f"{ten}_hover", sang(nen, 0.25), bong=8, m=(20, 10, 20, 14)))
    p(f"{pre}/styles/pressed", hop(f"{ten}_pressed", sang(nen, -0.12), bong=2, m=(20, 14, 20, 10)))
    p(f"{pre}/styles/hover_pressed", hop(f"{ten}_hover_pressed", sang(nen, -0.06), bong=3, m=(20, 13, 20, 11)))
    p(f"{pre}/styles/disabled", hop(f"{ten}_disabled", "C9BFD0" if vien_chu else "E8E0D0",
                                    border_a=0.35, m=(20, 10, 20, 14)))
    p(f"{pre}/styles/focus", FOCUS)
    for k in ("font_color", "font_hover_color", "font_pressed_color", "font_focus_color",
              "font_hover_pressed_color"):
        p(f"{pre}/colors/{k}", mau(chu))
    p(f"{pre}/colors/font_disabled_color", mau(TRANG, 0.85) if vien_chu else mau(MUC, 0.4))
    p(f"{pre}/colors/icon_normal_color", mau(chu))
    p(f"{pre}/colors/icon_hover_color", mau(chu))
    p(f"{pre}/colors/icon_pressed_color", mau(chu))
    p(f"{pre}/colors/icon_focus_color", mau(chu))
    p(f"{pre}/colors/icon_disabled_color", mau(MUC, 0.35))
    if vien_chu:
        p(f"{pre}/colors/font_outline_color", mau(vien_chu))
        p(f"{pre}/constants/outline_size", "8")
    if base:
        p("Button/fonts/font", F_TIEU_DE)
        p("Button/font_sizes/font_size", "26")
        p("Button/constants/h_separation", "12")
        p("Button/constants/icon_max_width", "48")
    else:
        p(f"{ten}/base_type", '&"Button"')


nut("Button", KEM)
nut("NutVang", VANG)
nut("NutTrang", TRANG)
nut("NutLa", LA, TRANG, MUC)
nut("NutDo", DO, TRANG, MUC)
nut("NutTroi", TROI, TRANG, MUC)
nut("NutCam", CAM, TRANG, MUC)
nut("NutHong", HONG, TRANG, MUC)
nut("NutTim", TIM, TRANG, MUC)

# Nút phẳng (icon nhỏ, mũi tên): không khối.
p("NutPhang/base_type", '&"Button"')
for st in ("normal", "pressed", "disabled", "hover_pressed"):
    p(f"NutPhang/styles/{st}", sub(f"NutPhang_{st}", "StyleBoxEmpty"))
p("NutPhang/styles/hover", hop("NutPhang_hover", MUC, bw=0, r=16, bg_a=0.08, m=(8, 4, 8, 4)))

# ---------- CheckButton / CheckBox ----------
# Bật/tắt thể hiện bằng icon công tắc, nền giữ như thường (không "lún").
for t in ("CheckButton", "CheckBox"):
    p(f"{t}/styles/pressed", 'SubResource("Button_normal")')
    p(f"{t}/styles/hover_pressed", 'SubResource("Button_hover")')
p("CheckButton/icons/checked", I_BAT)
p("CheckButton/icons/unchecked", I_TAT)
p("CheckButton/icons/checked_disabled", I_BAT)
p("CheckButton/icons/unchecked_disabled", I_TAT)
p("CheckButton/fonts/font", F_THAN)
p("CheckButton/font_sizes/font_size", "24")
p("CheckButton/constants/h_separation", "16")
p("CheckBox/icons/checked", I_TICH_BAT)
p("CheckBox/icons/unchecked", I_TICH_TAT)
p("CheckBox/icons/radio_checked", I_TICH_BAT)
p("CheckBox/icons/radio_unchecked", I_TICH_TAT)
p("CheckBox/fonts/font", F_THAN)
p("CheckBox/font_sizes/font_size", "22")

# ---------- OptionButton / Popup ----------
p("OptionButton/icons/arrow", I_XUONG)
p("OptionButton/constants/arrow_margin", "14")
p("OptionButton/fonts/font", F_THAN)
p("OptionButton/font_sizes/font_size", "22")
POP = hop("Popup", KEM, bw=4, r=18, bong=6, m=(10, 10, 10, 10))
p("PopupMenu/styles/panel", POP)
p("PopupMenu/styles/hover", hop("Popup_hover", VANG, bw=0, r=12, m=(8, 4, 8, 4)))
p("PopupMenu/colors/font_color", mau(MUC))
p("PopupMenu/colors/font_hover_color", mau(MUC))
p("PopupMenu/font_sizes/font_size", "22")
p("PopupMenu/constants/v_separation", "12")
p("PopupPanel/styles/panel", POP)
p("TooltipPanel/styles/panel", hop("Tooltip", MUC, border=MUC, bw=0, r=12, m=(12, 8, 12, 8)))
p("TooltipLabel/colors/font_color", mau(KEM))
p("TooltipLabel/font_sizes/font_size", "18")

# ---------- Label + biến thể ----------
p("Label/colors/font_color", mau(MUC))
p("Label/colors/font_outline_color", mau(MUC))
p("Label/colors/font_shadow_color", mau(MUC, 0))
p("Label/fonts/font", F_THAN)

p("ChuTieuDe/base_type", '&"Label"')
p("ChuTieuDe/fonts/font", F_TIEU_DE)
p("ChuTieuDe/font_sizes/font_size", "56")
p("ChuTieuDe/colors/font_color", mau(TRANG))
p("ChuTieuDe/colors/font_outline_color", mau(MUC))
p("ChuTieuDe/colors/font_shadow_color", mau(MUC))
p("ChuTieuDe/constants/outline_size", "14")
p("ChuTieuDe/constants/shadow_outline_size", "14")
p("ChuTieuDe/constants/shadow_offset_x", "0")
p("ChuTieuDe/constants/shadow_offset_y", "6")

p("ChuDauMuc/base_type", '&"Label"')
p("ChuDauMuc/fonts/font", F_TIEU_DE)
p("ChuDauMuc/font_sizes/font_size", "30")
p("ChuDauMuc/colors/font_color", mau(MUC))

p("ChuNhan/base_type", '&"Label"')
p("ChuNhan/fonts/font", F_DAM)
p("ChuNhan/font_sizes/font_size", "17")
p("ChuNhan/colors/font_color", mau(MUC, 0.6))

p("ChuPhu/base_type", '&"Label"')
p("ChuPhu/font_sizes/font_size", "19")
p("ChuPhu/colors/font_color", mau(MUC, 0.7))

p("ChuNoi/base_type", '&"Label"')
p("ChuNoi/fonts/font", F_DAM)
p("ChuNoi/font_sizes/font_size", "22")
p("ChuNoi/colors/font_color", mau(TRANG))
p("ChuNoi/colors/font_outline_color", mau(MUC))
p("ChuNoi/constants/outline_size", "8")

p("ChuSo/base_type", '&"Label"')
p("ChuSo/fonts/font", F_TIEU_DE)
p("ChuSo/font_sizes/font_size", "40")
p("ChuSo/colors/font_color", mau(TRANG))
p("ChuSo/colors/font_outline_color", mau(MUC))
p("ChuSo/constants/outline_size", "10")

# ---------- RichTextLabel ----------
p("RichTextLabel/colors/default_color", mau(MUC))
p("RichTextLabel/fonts/normal_font", F_THAN)
p("RichTextLabel/fonts/bold_font", F_DAM)
p("RichTextLabel/font_sizes/normal_font_size", "22")
p("RichTextLabel/font_sizes/bold_font_size", "22")
p("RichTextLabel/constants/line_separation", "4")

# ---------- Panel ----------
def khung(ten, nen, bw=5, r=28, bong=10, m=(24, 20, 24, 24), base=True):
    s = hop(f"{ten}_panel", nen, bw=bw, r=r, bong=bong, m=m)
    p(f"{ten}/styles/panel", s)
    if not base:
        p(f"{ten}/base_type", '&"PanelContainer"')


khung("PanelContainer", KEM)
p("Panel/styles/panel", 'SubResource("PanelContainer_panel")')
khung("KhungTroi", TROI, base=False)
khung("KhungVang", VANG, base=False)
khung("KhungHong", HONG, base=False)
khung("KhungCam", CAM, base=False)
khung("KhungTim", TIM, base=False)
khung("KhungLa", LA, base=False)
khung("KhungTrang", TRANG, base=False)
khung("KhungMuc", MUC, bw=0, bong=0, base=False)
khung("ThePill", TRANG, bw=4, r=999, bong=4, m=(16, 4, 16, 6), base=False)
khung("ThePillMuc", MUC, bw=0, r=999, bong=0, m=(14, 4, 14, 5), base=False)
khung("TheNho", TRANG, bw=4, r=18, bong=5, m=(14, 10, 14, 12), base=False)
khung("PillVang", VANG, bw=4, r=999, bong=4, m=(18, 6, 18, 8), base=False)
khung("PillCam", CAM, bw=4, r=999, bong=4, m=(18, 6, 18, 8), base=False)
p("KhungTrong/base_type", '&"PanelContainer"')
p("KhungTrong/styles/panel", sub("KhungTrong_panel", "StyleBoxEmpty"))

# ---------- LineEdit / TextEdit ----------
O_NHAP = hop("Nhap_normal", TRANG, bw=4, r=18, m=(16, 10, 16, 10))
p("LineEdit/styles/normal", O_NHAP)
p("LineEdit/styles/focus", FOCUS)
p("LineEdit/styles/read_only", hop("Nhap_ro", KEM_DAM, bw=4, r=18, border_a=0.5, m=(16, 10, 16, 10)))
p("LineEdit/fonts/font", F_DAM)
p("LineEdit/font_sizes/font_size", "24")
p("LineEdit/colors/font_color", mau(MUC))
p("LineEdit/colors/font_placeholder_color", mau(MUC, 0.38))
p("LineEdit/colors/font_uneditable_color", mau(MUC, 0.5))
p("LineEdit/colors/caret_color", mau(MUC))
p("LineEdit/colors/selection_color", mau(VANG, 0.7))
p("LineEdit/constants/caret_width", "3")
p("TextEdit/styles/normal", O_NHAP)
p("TextEdit/styles/focus", FOCUS)
p("TextEdit/colors/font_color", mau(MUC))

# ---------- Slider ----------
for t in ("HSlider", "VSlider"):
    p(f"{t}/styles/slider", hop(f"{t}_ray", KEM_DAM, bw=4, r=999, m=(8, 8, 8, 8)))
    p(f"{t}/styles/grabber_area", hop(f"{t}_day", VANG, bw=4, r=999, m=(8, 8, 8, 8)))
    p(f"{t}/styles/grabber_area_highlight", hop(f"{t}_day_sang", "FFE07A", bw=4, r=999, m=(8, 8, 8, 8)))
    p(f"{t}/icons/grabber", I_KEO)
    p(f"{t}/icons/grabber_highlight", I_KEO_SANG)
    p(f"{t}/icons/grabber_disabled", I_KEO_TAT)
    p(f"{t}/styles/focus", FOCUS)

# ---------- ProgressBar ----------
p("ProgressBar/styles/background", hop("Thanh_nen", KEM_DAM, bw=4, r=999, m=(4, 4, 4, 4)))
p("ProgressBar/styles/fill", hop("Thanh_day", LA, bw=4, r=999, m=(4, 4, 4, 4)))
p("ProgressBar/fonts/font", F_TIEU_DE)
p("ProgressBar/colors/font_color", mau(TRANG))
p("ProgressBar/colors/font_outline_color", mau(MUC))
p("ProgressBar/constants/outline_size", "6")

# ---------- Scroll ----------
for t in ("VScrollBar", "HScrollBar"):
    p(f"{t}/styles/scroll", hop(f"{t}_ray", MUC, bw=0, r=999, bg_a=0.12, m=(6, 6, 6, 6)))
    p(f"{t}/styles/grabber", hop(f"{t}_keo", CAM, bw=3, r=999, m=(6, 6, 6, 6)))
    p(f"{t}/styles/grabber_highlight", hop(f"{t}_keo_sang", sang(CAM, 0.2), bw=3, r=999, m=(6, 6, 6, 6)))
    p(f"{t}/styles/grabber_pressed", hop(f"{t}_keo_bam", sang(CAM, -0.12), bw=3, r=999, m=(6, 6, 6, 6)))
p("ScrollContainer/styles/panel", sub("Scroll_panel", "StyleBoxEmpty"))

# ---------- ItemList ----------
p("ItemList/styles/panel", hop("DS_panel", TRANG, bw=4, r=18, m=(8, 8, 8, 8)))
p("ItemList/styles/focus", sub("DS_focus", "StyleBoxEmpty"))
p("ItemList/styles/selected", hop("DS_chon", VANG, bw=3, r=12, m=(6, 4, 6, 4)))
p("ItemList/styles/selected_focus", hop("DS_chon_f", VANG, bw=3, r=12, m=(6, 4, 6, 4)))
p("ItemList/styles/hovered", hop("DS_hover", KEM_DAM, bw=0, r=12, m=(6, 4, 6, 4)))
p("ItemList/styles/cursor", hop("DS_cursor", VANG, border=CAM, bw=3, r=12, center=False, m=(6, 4, 6, 4)))
p("ItemList/styles/cursor_unfocused", sub("DS_cursor_u", "StyleBoxEmpty"))
p("ItemList/colors/font_color", mau(MUC))
p("ItemList/colors/font_hovered_color", mau(MUC))
p("ItemList/colors/font_selected_color", mau(MUC))
p("ItemList/font_sizes/font_size", "20")
p("ItemList/constants/v_separation", "8")

# ---------- Separator ----------
p("HSeparator/styles/separator", sub("Ngan_ngang", "StyleBoxLine",
                                      color=mau(MUC, 0.18), thickness="4"))
p("HSeparator/constants/separation", "16")
p("VSeparator/styles/separator", sub("Ngan_doc", "StyleBoxLine",
                                      color=mau(MUC, 0.18), thickness="4", vertical="true"))
p("VSeparator/constants/separation", "16")

# ---------- TabBar / TabContainer ----------
for t in ("TabBar", "TabContainer"):
    p(f"{t}/styles/tab_selected", hop(f"{t}_chon", VANG, bw=4, r=16, bong=0, m=(18, 8, 18, 8)))
    p(f"{t}/styles/tab_unselected", hop(f"{t}_khong", KEM_DAM, bw=4, r=16, m=(18, 8, 18, 8)))
    p(f"{t}/styles/tab_hovered", hop(f"{t}_hover", TRANG, bw=4, r=16, m=(18, 8, 18, 8)))
    p(f"{t}/styles/tab_focus", FOCUS)
    p(f"{t}/fonts/font", F_TIEU_DE)
    p(f"{t}/font_sizes/font_size", "22")
    for k in ("font_selected_color", "font_unselected_color", "font_hovered_color"):
        p(f"{t}/colors/{k}", mau(MUC))
p("TabContainer/styles/panel", sub("Tab_panel", "StyleBoxEmpty"))

# ---------- SpinBox ----------
p("SpinBox/constants/buttons_width", "28")

# ---------- Xuất ----------
out = [f'[gd_resource type="Theme" load_steps={len(ext) + len(subs) + 1} format=3]', ""]
for id_, type_, path in ext:
    out.append(f'[ext_resource type="{type_}" path="{path}" id="{id_}"]')
out.append("")
out += [s + "\n" for s in subs]
out.append("[resource]")
out += props
Path("ui/theme/cartoon_theme.tres").write_text("\n".join(out) + "\n", encoding="utf-8")
print("ok", len(subs), "sub,", len(props), "props")
