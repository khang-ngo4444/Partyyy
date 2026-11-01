"""Gắn vật liệu ngoài và tách mesh ra .res trong file .import của các .glb đảo.

    python 3d/ban_do/va_import.py    # sau khi Godot quét xong .glb, rồi reimport trong editor

Godot tạo .import lần đầu; script này chỉ sửa các khoá import, không đụng scene.
"""
import json
import os
import re

GOC = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
THU_MUC = os.path.join(GOC, "asset", "generated", "dao_lon")
# Tên vật liệu trong .glb -> tên file .tres trong materials/dao_lon.
VAT_LIEU = {"dat": "dat", "la": "la", "nuoc": "nuoc", "dung_nham": "dung_nham", "da": "da", "tia_sang": "tia_sang",
        "may": "may", "mau": "son", "kim": "kim", "phat_sang": "phat_sang"}
CAN_TANGENT = {"nuoc.glb"}


def _khoi_con(goc, meshes):
    du_lieu = {
        "materials": {vl: {"use_external/enabled": True,
                "use_external/path": f"res://materials/dao_lon/{tep}.tres"} for vl, tep in VAT_LIEU.items()},
        # Godot đặt tên mesh glTF là "<tên file>_<tên mesh>".
        "meshes": {f"{goc}_{m}": {"save_to_file/enabled": True,
                "save_to_file/path": f"res://asset/generated/dao_lon/mesh/{m}.res"} for m in meshes},
    }
    return json.dumps(du_lieu, ensure_ascii=False)


def main():
    with open(os.path.join(THU_MUC, "danh_sach_mesh.json"), encoding="utf-8") as f:
        danh_sach = json.load(f)
    for ten_glb, meshes in danh_sach.items():
        duong = os.path.join(THU_MUC, ten_glb + ".import")
        with open(duong, encoding="utf-8") as f:
            txt = f.read()
        txt = re.sub(r"_subresources=.*", lambda _m: "_subresources=" + _khoi_con(ten_glb[:-4], meshes), txt)
        tang = "true" if ten_glb in CAN_TANGENT else "false"
        txt = re.sub(r"meshes/ensure_tangents=\w+", f"meshes/ensure_tangents={tang}", txt)
        with open(duong, "w", encoding="utf-8") as f:
            f.write(txt)
        print("đã vá", ten_glb)


if __name__ == "__main__":
    main()
