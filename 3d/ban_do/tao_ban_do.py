"""Sinh toàn bộ mesh đảo bàn party thành .glb cho Godot import.

    python 3d/ban_do/tao_ban_do.py          # chạy ở gốc PartyBash; cần numpy + scipy

Vào: vị trí ô trong `board/ban_party.tscn`. Dời ô thì chạy lại để đường, bệ ô, sông khớp theo.
Ra: `asset/generated/dao_lon/*.glb`, mỗi mesh mang tên riêng; `vat_lieu.json` liệt kê tên mesh.
Scene `board/ban_party_map.tscn` dựng bằng tay trong editor từ các mesh này.
"""
import json
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import cong_trinh as ct  # noqa: E402
import dia_hinh as dh_mod  # noqa: E402
import thuc_vat as tv  # noqa: E402
from hinh import Lo, TAU, bien_doi, ghi_glb, mau  # noqa: E402

GOC = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
RA = os.path.join(GOC, "asset", "generated", "dao_lon")
HAT = 2026


def _theo_khu(bang_khu, tien_to):
    return {f"{tien_to}_{a}_{b}": lo.gop() for (a, b), lo in bang_khu.items() if not lo.rong()}


def _xuat(ten_file, meshes, ghi_chu):
    tong = ghi_glb(os.path.join(RA, ten_file), meshes)
    ghi_chu[ten_file] = sorted(meshes)
    print(f"{ten_file}: {len(meshes)} mesh, {tong:,} tam giác")
    return tong


def _dao_xa(rng):
    """Các đảo xa + cột đá; gộp theo vị trí để culling."""
    lo_gan, lo_xa = Lo(), Lo()
    for k in range(16):
        a = k / 16 * TAU + rng.uniform(-.1, .1)
        r = rng.uniform(70, 88)
        x, z = np.cos(a) * r, np.sin(a) * r
        if abs(np.arctan2(z, x) - np.arctan2(13, 62)) < .22:
            continue
        cao = rng.uniform(7, 19)
        h = dh_mod.cot_da(rng, cao, rng.uniform(1.8, 4.2))
        lo_gan.them("da", h, bien_doi((x, dh_mod.MUC_NUOC + cao * .32, z), rng.uniform(0, TAU)), mau("#8d8c86"))
    for k in range(11):
        a = k / 11 * TAU + rng.uniform(-.14, .14)
        r = rng.uniform(150, 300)
        lo_xa.them("dat", dh_mod.dao_xa(rng, rng.uniform(14, 30), rng.uniform(8, 26)),
                bien_doi((np.cos(a) * r, 0, np.sin(a) * r), rng.uniform(0, TAU)))
    return {"cot_da": lo_gan.gop(), "dao_xa": lo_xa.gop()}


def main():
    os.makedirs(RA, exist_ok=True)
    rng = np.random.default_rng(HAT)
    dh = dh_mod.DiaHinh(dh_mod.doc_o(os.path.join(GOC, "board", "ban_party.tscn")))
    print("Địa hình OK: cao nhất", round(float(dh.H.max()), 1))
    ghi, tong = {}, 0
    tong += _xuat("dia_hinh.glb", dh.khoi_dat(), ghi)

    nuoc = {"song": {"nuoc": dh_mod.mat_song(dh)}, "dung_nham": {"dung_nham": dh_mod.dung_nham(dh, rng)}}
    tong += _xuat("nuoc.glb", nuoc, ghi)
    tong += _xuat("duong.glb", _theo_khu(dh_mod.lat_duong(dh, rng), "duong"), ghi)

    cay, co = tv.trong_cay(dh, rng)
    tong += _xuat("cay.glb", _theo_khu(cay, "cay"), ghi)
    tong += _xuat("co.glb", _theo_khu(co, "co"), ghi)

    cong_trinh = {"hai_dang": ct.hai_dang(), "cang": ct.cang(), "hoi_cho": ct.hoi_cho(), "den_thap": ct.den_thap(),
            "vinh_cuop": ct.vinh_cuop(), "coi_xay_tay": ct.coi_xay("coi_xay_tay"),
            "coi_xay_dong": ct.coi_xay("coi_xay_dong"), "lang_nam": ct.lang_nam(), "den_ven_duong": ct.den_ven_duong(dh)}
    tong += _xuat("cong_trinh.glb", {k: v.gop() for k, v in cong_trinh.items()}, ghi)

    dong = {"tau_buom": ct.tau_buom().gop(), "vong_quay": ct.vong_quay().gop(), "canh_quat": ct.canh_quat().gop(),
            "tia_den": {"tia_sang": ct.tia_den()}, "tinh_the": {"phat_sang": ct.tinh_the()},
            "chim": {"mau": ct.chim(rng)}}
    for k in range(3):
        dong[f"may_{k}"] = {"may": ct.may(rng)}
    tong += _xuat("chuyen_dong.glb", dong, ghi)
    tong += _xuat("dao_xa.glb", _dao_xa(rng), ghi)

    with open(os.path.join(RA, "danh_sach_mesh.json"), "w", encoding="utf-8") as f:
        json.dump(ghi, f, ensure_ascii=False, indent=1)
    print(f"TỔNG {tong:,} tam giác")


if __name__ == "__main__":
    main()
