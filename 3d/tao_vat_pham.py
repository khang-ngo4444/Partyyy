"""Dựng mô hình 3D vật phẩm thành .glb (hình + vật liệu + animation) cho Godot import.

    py -3.10 3d/tao_vat_pham.py      # chạy ở gốc PartyBash; cần numpy

Nguồn hình: `3d/vat_pham/nguon.json` (mỗi món một danh sách khối: trụ, cầu, xuyến, hộp, viên
nang, lăng trụ — tham số giống Godot). Animation khai báo ở phần "animation từng món" bên dưới.
Ra: `3d/vat_pham/<món>.glb`. Godot tự tạo `AnimationPlayer` với các animation:
  - "dung": diễn lúc dùng món. Hướng "trước" của món là −Z.
  - "hien": rơi xuống nảy lên khi đặt trên ô (chỉ rào, bẫy, neo).
Mọi khối nằm dưới node "Goc"; animation chạy trên "Goc" hoặc trên từng khối.
Cuối file còn các mô hình hiệu ứng dùng đồ (dừa, trâu, cục nổ, đồng xu) -> `3d/hieu_ung/*.glb`.
"""
import json
import math
import os
import struct

import numpy as np

THU_MUC = os.path.join(os.path.dirname(os.path.abspath(__file__)), "vat_pham")
TAU = math.tau

# ───────────────────────────── khối hình (theo quy ước mesh của Godot) ─────────────────────────────


def _vong(r, y, n):
    a = np.linspace(0.0, TAU, n, endpoint=False)
    return np.stack([np.sin(a) * r, np.full(n, y), np.cos(a) * r], axis=1)


def _luoi(hang):
    """Nối các hàng điểm (mỗi hàng n điểm, khép vòng) thành tam giác."""
    v = np.concatenate(hang)
    n = len(hang[0])
    tri = []
    for i in range(len(hang) - 1):
        for j in range(n):
            a, b = i * n + j, i * n + (j + 1) % n
            c, d = a + n, b + n
            tri += [(a, c, b), (b, c, d)]
    return v, tri


def _nap(tam, vong):
    """Nắp phẳng: tâm + vòng (đỉnh riêng để mặt phẳng)."""
    v = np.concatenate([[tam], vong])
    n = len(vong)
    return v, [(0, 1 + j, 1 + (j + 1) % n) for j in range(n)]


def tru(p):
    tr, br = p.get("top_radius", 0.5), p.get("bottom_radius", 0.5)
    h, n = p.get("height", 2.0), int(p.get("radial_segments", 64))
    khoi = [_luoi([_vong(br, -h / 2, n), _vong(tr, h / 2, n)])]
    if tr > 0:
        khoi.append(_nap([0, h / 2, 0], _vong(tr, h / 2, n)))
    if br > 0:
        khoi.append(_nap([0, -h / 2, 0], _vong(br, -h / 2, n)))
    return khoi


def cau(p):
    r, h = p.get("radius", 0.5), p.get("height", 1.0)
    n, m = int(p.get("radial_segments", 64)), int(p.get("rings", 32)) + 1
    hang = []
    for i in range(m + 1):
        phi = math.pi * i / m
        hang.append(_vong(math.sin(phi) * r, -math.cos(phi) * h / 2, n))
    return [_luoi(hang)]


def xuyen(p):
    ri, ro = p.get("inner_radius", 0.5), p.get("outer_radius", 1.0)
    R, r = (ri + ro) / 2, (ro - ri) / 2
    n, m = int(p.get("rings", 64)), int(p.get("ring_segments", 32))
    hang = []
    for i in range(m + 1):
        t = TAU * i / m
        hang.append(_vong(R + r * math.cos(t), r * math.sin(t), n))
    return [_luoi(hang)]


def hop(p):
    sx, sy, sz = np.array(p.get("size", [1, 1, 1])) / 2
    khoi = []
    for truc in range(3):
        for dau in (-1, 1):
            u, w = [k for k in range(3) if k != truc]
            q = np.zeros((4, 3))
            for i, (a, b) in enumerate([(-1, -1), (1, -1), (1, 1), (-1, 1)]):
                q[i, truc], q[i, u], q[i, w] = dau, a, b
            khoi.append((q * [sx, sy, sz], [(0, 1, 2), (0, 2, 3)]))
    return khoi


def vien_nang(p):
    r, h = p.get("radius", 0.5), p.get("height", 2.0)
    n, m = int(p.get("radial_segments", 64)), max(int(p.get("rings", 8)), 2)
    hang = []
    for i in range(m + 1):
        phi = math.pi / 2 * i / m
        hang.append(_vong(math.sin(phi) * r, -(h / 2 - r) - math.cos(phi) * r, n))
    for i in range(m + 1):
        phi = math.pi / 2 * i / m
        hang.append(_vong(math.cos(phi) * r, (h / 2 - r) + math.sin(phi) * r, n))
    return [_luoi(hang)]


def lang_tru(p):
    sx, sy, sz = np.array(p.get("size", [1, 1, 1])) / 2
    dinh = -sx + p.get("left_to_right", 0.5) * 2 * sx
    tg = [(-sx, -sy), (sx, -sy), (dinh, sy)]
    khoi = []
    for z in (-sz, sz):
        khoi.append((np.array([[x, y, z] for x, y in tg]), [(0, 1, 2)]))
    for i in range(3):
        (x0, y0), (x1, y1) = tg[i], tg[(i + 1) % 3]
        khoi.append((np.array([[x0, y0, -sz], [x1, y1, -sz], [x1, y1, sz], [x0, y0, sz]]),
                     [(0, 1, 2), (0, 2, 3)]))
    return khoi


DUNG = {"Cylinder": tru, "Sphere": cau, "Torus": xuyen, "Box": hop, "Capsule": vien_nang,
        "Prism": lang_tru}


def dung_luoi(loai, p, bien=None):
    """-> (vị trí, pháp tuyến, chỉ số) đã quay mặt ra ngoài; `bien` = ma trận 4x4 nắn hình."""
    vs, ns, ids = [], [], []
    goc = 0
    for v, tri in DUNG[loai](p):
        v = np.asarray(v, float)
        tri = np.asarray(tri, int).reshape(-1, 3)
        # Mặt quay ra ngoài: so với tâm khối (xuyến thì so với vòng tâm ống).
        a, b, c = v[tri[:, 0]], v[tri[:, 1]], v[tri[:, 2]]
        fn = np.cross(b - a, c - a)
        g = (a + b + c) / 3
        if loai == "Torus":
            R = (p.get("inner_radius", 0.5) + p.get("outer_radius", 1.0)) / 2
            xz = g[:, [0, 2]]
            l = np.linalg.norm(xz, axis=1, keepdims=True) + 1e-9
            ref = g - np.insert(xz / l * R, 1, 0.0, axis=1)
        else:
            ref = g
        nguoc = np.einsum("ij,ij->i", fn, ref) < 0
        tri[nguoc] = tri[nguoc][:, [0, 2, 1]]
        n = np.zeros_like(v)
        a, b, c = v[tri[:, 0]], v[tri[:, 1]], v[tri[:, 2]]
        fn = np.cross(b - a, c - a)
        for k in range(3):
            np.add.at(n, tri[:, k], fn)
        n /= np.linalg.norm(n, axis=1, keepdims=True) + 1e-12
        vs.append(v)
        ns.append(n)
        ids.append(tri + goc)
        goc += len(v)
    v, n, i = np.concatenate(vs), np.concatenate(ns), np.concatenate(ids)
    if bien is not None:
        v = v @ bien[:3, :3].T + bien[:3, 3]
        n = n @ np.linalg.inv(bien[:3, :3])
        n /= np.linalg.norm(n, axis=1, keepdims=True) + 1e-12
    return v.astype(np.float32), n.astype(np.float32), i.astype(np.uint32).ravel()


# ───────────────────────────── phép quay ─────────────────────────────


def quat_euler(x, y, z):
    """Euler kiểu Godot (YXZ) -> quaternion (x, y, z, w)."""
    def q(ax, a):
        s = math.sin(a / 2)
        return np.array([ax[0] * s, ax[1] * s, ax[2] * s, math.cos(a / 2)])

    def nhan(a, b):
        ax, ay, az, aw = a
        bx, by, bz, bw = b
        return np.array([aw * bx + ax * bw + ay * bz - az * by,
                         aw * by - ax * bz + ay * bw + az * bx,
                         aw * bz + ax * by - ay * bx + az * bw,
                         aw * bw - ax * bx - ay * by - az * bz])
    return nhan(nhan(q((0, 1, 0), y), q((1, 0, 0), x)), q((0, 0, 1), z))


def quat_ma_tran(m):
    t = np.trace(m)
    if t > 0:
        s = math.sqrt(t + 1) * 2
        return np.array([(m[2, 1] - m[1, 2]) / s, (m[0, 2] - m[2, 0]) / s,
                         (m[1, 0] - m[0, 1]) / s, s / 4])
    i = int(np.argmax(np.diag(m)))
    j, k = (i + 1) % 3, (i + 2) % 3
    s = math.sqrt(1 + m[i, i] - m[j, j] - m[k, k]) * 2
    q = np.zeros(4)
    q[i] = s / 4
    q[j] = (m[j, i] + m[i, j]) / s
    q[k] = (m[k, i] + m[i, k]) / s
    q[3] = (m[k, j] - m[j, k]) / s
    return q


def tach_trs(t12):
    """Transform3D của Godot (hàng của basis + gốc) -> (T, R, S); không xử lý xiên."""
    b = np.array(t12[:9], float).reshape(3, 3)
    s = np.linalg.norm(b, axis=0)
    r = b / s
    if np.linalg.det(r) < 0:
        s[0], r[:, 0] = -s[0], -r[:, 0]
    return list(t12[9:12]), quat_ma_tran(r), s


# ───────────────────────────── animation từng món ─────────────────────────────
# Mỗi rãnh: (node, "translation"|"rotation"|"scale", [(giây, giá trị)], "LINEAR"|"STEP").
# rotation viết bằng Euler (x, y, z) radian; tự đổi sang quaternion.

V0 = (0, 0, 0)
V1 = (1, 1, 1)
AN = (0, 0, 0)  # scale 0 = ẩn


def xoay_y(t0, t1, vong):
    """Quay quanh Y `vong` vòng: chia mỗi 1/4 vòng một key để nội suy không đi tắt."""
    n = int(vong * 4)
    return [(t0 + (t1 - t0) * i / n, (0, TAU * vong * i / n, 0)) for i in range(n + 1)]


def dung_mac_dinh(_):
    """Món dùng tại chỗ: nảy lên, xoay một vòng, đáp."""
    return [("Goc", "translation", [(0, V0), (0.25, (0, 0.35, 0)), (0.5, V0),
                                    (0.62, (0, 0.08, 0)), (0.75, V0)], "LINEAR"),
            ("Goc", "rotation", xoay_y(0, 0.5, 1), "LINEAR")]


def dung_can_cau(vt):
    phao = np.array(vt["Sph1"])
    xa = tuple(phao + [2.4, 0, 0])
    phao = tuple(phao)
    quay = lambda z: (0, math.pi / 2, z)  # cần dựng theo +X; +90° quanh Y để +X thành −Z
    return [("Goc", "rotation", [(0, quay(0)), (0.2, quay(0.5)), (0.35, quay(-0.3)),
                                 (0.5, quay(0)), (1.0, quay(0))], "LINEAR"),
            ("Sph1", "translation", [(0, phao), (0.35, phao), (0.6, xa), (0.8, xa),
                                     (1.0, phao)], "LINEAR"),
            ("Day", "scale", [(0, AN), (0.349, AN), (0.35, (0.001, 1, 1)), (0.6, (2.4, 1, 1)),
                              (0.8, (2.4, 1, 1)), (0.99, (0.001, 1, 1)), (1.0, AN)], "LINEAR")]


def dung_na(vt):
    da = np.array(vt["Sph2"])
    return [("Goc", "translation", [(0, V0), (0.3, (0, 0, 0.1)), (0.36, V0)], "LINEAR"),
            ("Sph2", "translation", [(0, tuple(da)), (0.3, tuple(da + [0, 0, 0.1])),
                                     (0.36, tuple(da + [0, 0, -0.4])),
                                     (0.65, tuple(da + [0, 0.1, -3.2])), (0.8, tuple(da))],
             "LINEAR"),
            ("Sph2", "scale", [(0, V1), (0.65, AN), (0.8, V1)], "STEP")]


def dung_dep(_):
    return [("Goc", "translation", [(0, V0), (0.35, (0, 0, -2.5)), (0.75, V0)], "LINEAR"),
            ("Goc", "rotation", xoay_y(0, 0.75, 2), "LINEAR")]


def dung_vot(_):
    return [("Goc", "rotation", [(0, V0), (0.2, (0.5, 0, 0)), (0.4, (-1.1, 0, 0)),
                                 (0.8, V0)], "LINEAR")]


def dung_kinh_lup(_):
    tat, bat = (1, 1, 0.001), (1, 1, 3.0)
    return [("Tia", "scale", [(0, AN), (0.149, AN), (0.15, tat), (0.35, bat), (0.7, bat),
                              (0.89, tat), (0.9, AN)], "LINEAR")]


def hien_tren_o(_):
    """Đặt lên ô: rơi xuống rồi nảy (mô hình được phóng ×4 ở scene trên ô)."""
    return [("Goc", "translation", [(0, (0, 0.375, 0)), (0.25, V0)], "LINEAR"),
            ("Goc", "scale", [(0, (0.12, 0.12, 0.12)), (0.25, (1.15, 1.15, 1.15)),
                              (0.45, V1)], "LINEAR")]


DUNG_RIENG = {"can_cau": dung_can_cau, "sung_1_phat": dung_na, "dep_to_ong": dung_dep,
              "vot_luoi": dung_vot, "kinh_lup": dung_kinh_lup}
TREN_O = {"rao_tre", "vo_sau_rieng", "day_thun"}

# Khối phụ chỉ hiện lúc diễn (ẩn = scale 0): (món, tên, đặt tại, bán kính, màu, nắn hình).
KHOI_PHU = {
    # Dây câu: trụ dài 1 m nằm dọc +X tính từ gốc (tại phao).
    "can_cau": [("Day", "Sph1", 0.006, (0.95, 0.95, 0.9, 1), "x")],
    # Tia nắng: trụ dài 1 m dọc −Z tính từ tâm kính.
    "kinh_lup": [("Tia", (-0.06, 0.31, 0.0), 0.03, (1, 0.9, 0.3, 0.8), "-z")],
}


def nan_truc(huong):
    """Ma trận đặt trụ (dọc Y, tâm 0) thành thanh dài 1 m bắt đầu ở gốc theo `huong`."""
    m = np.eye(4)
    if huong == "x":
        m[:3, :3] = [[0, 1, 0], [-1, 0, 0], [0, 0, 1]]
        m[:3, 3] = [0.5, 0, 0]
    else:
        m[:3, :3] = [[1, 0, 0], [0, 0, 1], [0, -1, 0]]
        m[:3, 3] = [0, 0, -0.5]
    return m


# ───────────────────────────── ghi .glb ─────────────────────────────


class Glb:
    def __init__(self):
        self.g = {"asset": {"version": "2.0", "generator": "PartyBash 3d/tao_vat_pham.py"},
                  "scenes": [{"nodes": [0]}], "scene": 0, "nodes": [], "meshes": [],
                  "materials": [], "accessors": [], "bufferViews": [], "animations": []}
        self.bin = bytearray()
        self.dung_unlit = False

    def _view(self, data, target=None):
        while len(self.bin) % 4:
            self.bin.append(0)
        bv = {"buffer": 0, "byteOffset": len(self.bin), "byteLength": len(data)}
        if target:
            bv["target"] = target
        self.bin += data
        self.g["bufferViews"].append(bv)
        return len(self.g["bufferViews"]) - 1

    def acc(self, arr, kieu, target=None, minmax=False):
        arr = np.ascontiguousarray(arr)
        comp = 5125 if arr.dtype == np.uint32 else 5126
        a = {"bufferView": self._view(arr.tobytes(), target), "componentType": comp,
             "count": len(arr) if arr.ndim > 1 or kieu != "SCALAR" else arr.size, "type": kieu}
        if minmax:
            a["min"] = np.atleast_1d(arr.min(axis=0)).tolist()
            a["max"] = np.atleast_1d(arr.max(axis=0)).tolist()
        self.g["accessors"].append(a)
        return len(self.g["accessors"]) - 1

    def vat_lieu(self, ten, vl):
        mau = list(vl.get("albedo_color", [1, 1, 1, 1]))
        m = {"name": ten, "pbrMetallicRoughness": {
            "baseColorFactor": mau, "metallicFactor": float(vl.get("metallic", 0.0)),
            "roughnessFactor": float(vl.get("roughness", 1.0))}}
        if "emission" in vl:
            e = np.array(vl["emission"][:3]) * float(vl.get("emission_energy_multiplier", 1.0))
            m["emissiveFactor"] = np.clip(e, 0, 1).tolist()
        if vl.get("transparency", 0) or mau[3] < 1:
            m["alphaMode"] = "BLEND"
        if vl.get("shading_mode", 1) == 0:
            m["extensions"] = {"KHR_materials_unlit": {}}
            self.dung_unlit = True
        self.g["materials"].append(m)
        return len(self.g["materials"]) - 1

    def luoi(self, ten, v, n, i, mat):
        self.g["meshes"].append({"name": ten, "primitives": [{
            "attributes": {"POSITION": self.acc(v, "VEC3", 34962, True),
                           "NORMAL": self.acc(n, "VEC3", 34962)},
            "indices": self.acc(i, "SCALAR", 34963), "material": mat}]})
        return len(self.g["meshes"]) - 1

    def node(self, d):
        self.g["nodes"].append(d)
        return len(self.g["nodes"]) - 1

    def anim(self, ten, ray, chi_so):
        a = {"name": ten, "channels": [], "samplers": []}
        for node, duong, key, noi in ray:
            t = np.array([k[0] for k in key], np.float32)
            if duong == "rotation":
                gt = np.array([quat_euler(*k[1]) for k in key], np.float32)
                kieu = "VEC4"
            else:
                gt = np.array([k[1] for k in key], np.float32)
                kieu = "VEC3"
            a["samplers"].append({"input": self.acc(t, "SCALAR", minmax=True),
                                  "output": self.acc(gt, kieu), "interpolation": noi})
            a["channels"].append({"sampler": len(a["samplers"]) - 1,
                                  "target": {"node": chi_so[node], "path": duong}})
        self.g["animations"].append(a)

    def luu(self, duong):
        if self.dung_unlit:
            self.g["extensionsUsed"] = ["KHR_materials_unlit"]
        if not self.g["animations"]:
            del self.g["animations"]
        while len(self.bin) % 4:
            self.bin.append(0)
        self.g["buffers"] = [{"byteLength": len(self.bin)}]
        js = json.dumps(self.g, separators=(",", ":")).encode()
        js += b" " * (-len(js) % 4)
        tong = 12 + 8 + len(js) + 8 + len(self.bin)
        with open(duong, "wb") as f:
            f.write(struct.pack("<III", 0x46546C67, 2, tong))
            f.write(struct.pack("<II", len(js), 0x4E4F534A) + js)
            f.write(struct.pack("<II", len(self.bin), 0x004E4942) + bytes(self.bin))


def dung_mon(mon, nguon):
    glb = Glb()
    glb.node({"name": nguon["goc"], "children": [1]})
    goc_trong = glb.node({"name": "Goc", "children": []})
    chi_so = {"Goc": goc_trong}
    vi_tri = {}
    for k in nguon["phan"]:
        T, R, S = tach_trs(k["transform"])
        v, n, i = dung_luoi(k["loai"], k["tham_so"])
        lu = glb.luoi(k["ten"], v, n, i, glb.vat_lieu(k["ten"], k["vat_lieu"]))
        chi_so[k["ten"]] = glb.node({"name": k["ten"], "mesh": lu, "translation": T,
                                     "rotation": R.tolist(), "scale": S.tolist()})
        vi_tri[k["ten"]] = T
    for ten, dat, r, mau, huong in KHOI_PHU.get(mon, []):
        v, n, i = dung_luoi("Cylinder", {"top_radius": r, "bottom_radius": r, "height": 1.0,
                                         "radial_segments": 8}, nan_truc(huong))
        mat = glb.vat_lieu(ten, {"albedo_color": list(mau), "shading_mode": 0})
        chi_so[ten] = glb.node({"name": ten, "mesh": glb.luoi(ten, v, n, i, mat),
                                "translation": list(vi_tri[dat] if isinstance(dat, str) else dat),
                                "scale": [0, 0, 0]})
    glb.g["nodes"][goc_trong]["children"] = [c for c in chi_so.values() if c != goc_trong]
    glb.anim("dung", DUNG_RIENG.get(mon, dung_mac_dinh)(vi_tri), chi_so)
    if mon in TREN_O:
        glb.anim("hien", hien_tren_o(vi_tri), chi_so)
    glb.luu(os.path.join(THU_MUC, mon + ".glb"))


# ───────────────────────────── mô hình hiệu ứng dùng đồ ─────────────────────────────
# Ra `3d/hieu_ung/<tên>.glb` (đúng cỡ mét trong thế giới bàn). Scene hiệu ứng ở `board/hieu_ung/`
# instance các glb này và điều phối thời gian bằng AnimationPlayer của scene; animation dưới đây
# là phần chuyển động nội tại của model (vỡ, phi nước đại, nổ, quay), scene gọi `play`.
THU_MUC_HIEU_UNG = os.path.join(os.path.dirname(os.path.abspath(__file__)), "hieu_ung")


def ma_tran_euler(x, y, z):
    """Ma trận quay Euler YXZ kiểu Godot: R = Ry · Rx · Rz."""
    cx, sx, cy, sy, cz, sz = (math.cos(x), math.sin(x), math.cos(y), math.sin(y),
                              math.cos(z), math.sin(z))
    rx = np.array([[1, 0, 0], [0, cx, -sx], [0, sx, cx]])
    ry = np.array([[cy, 0, sy], [0, 1, 0], [-sy, 0, cy]])
    rz = np.array([[cz, -sz, 0], [sz, cz, 0], [0, 0, 1]])
    return ry @ rx @ rz


def phan(ten, loai, tham_so, mau, vt=(0, 0, 0), xoay=(0, 0, 0), to=(1, 1, 1), lech=None,
         an=False, **vl):
    """Một khối của model hiệu ứng. `lech` = dời hình khỏi gốc node (chân xoay ở hông);
    `an` = lúc nghỉ ẩn (scale 0), animation mới bật lên."""
    b = ma_tran_euler(*xoay) * np.array(to, float)
    # Hiệu ứng nhìn từ xa: ít cạnh cho nhẹ file.
    tham_so = {"radial_segments": 16, "rings": 8, **tham_so}
    return {"ten": ten, "loai": loai, "tham_so": tham_so,
            "vat_lieu": {"albedo_color": list(mau), **vl},
            "transform": [float(v) for v in b.ravel()] + [float(v) for v in vt],
            "lech": lech, "an": an}


KHOI_UNLIT = {"shading_mode": 0}


def hieu_ung_dua():
    """Dừa: quả nguyên + 3 mắt; animation "vo": quả biến mất, mảnh vỏ/cùi văng ra, nước bắn."""
    nau, trang = (0.36, 0.23, 0.11, 1), (0.96, 0.95, 0.9, 1)
    ps = [phan("Qua", "Sphere", {"radius": 0.38, "height": 0.76}, nau, roughness=0.95)]
    for i, (x, y, z) in enumerate([(-0.1, 0.28, -0.22), (0.1, 0.28, -0.22), (0.0, 0.2, -0.31)]):
        ps.append(phan("Mat%d" % (i + 1), "Sphere", {"radius": 0.05, "height": 0.1},
                       (0.1, 0.06, 0.03, 1), vt=(x, y, z)))
    huong = [(1, 0.3, 0), (-1, 0.4, 0.2), (0.3, 0.5, 1), (-0.4, 0.3, -1), (0.8, 0.6, -0.8),
             (-0.7, 0.5, 0.8)]
    for i in range(6):
        ps.append(phan("Manh%d" % (i + 1), "Box", {"size": [0.3, 0.1, 0.22]},
                       nau if i % 2 == 0 else trang, an=True, roughness=0.9))
    ps.append(phan("Nuoc", "Sphere", {"radius": 0.5, "height": 1.0}, (0.88, 0.96, 1, 0.75),
                   vt=(0, -0.3, 0), an=True, roughness=0.1))
    ray = [("Qua", "scale", [(0, V1), (0.02, AN)], "LINEAR")]
    for i in range(3):
        ray.append(("Mat%d" % (i + 1), "scale", [(0, V1), (0.02, AN)], "LINEAR"))
    for i, h in enumerate(huong):
        h = np.array(h) / np.linalg.norm(h)
        n = "Manh%d" % (i + 1)
        ray += [(n, "scale", [(0, AN), (0.03, V1), (0.7, V1), (0.9, AN)], "LINEAR"),
                (n, "translation",
                 [(0, V0), (0.4, tuple(h * 1.1 + [0, 0.7, 0])), (0.9, tuple(h * 1.5 - [0, 0.2, 0]))],
                 "LINEAR"),
                (n, "rotation", [(0, V0), (0.9, (3.0 + i, 2.0, 4.0 - i))], "LINEAR")]
    ray.append(("Nuoc", "scale", [(0, AN), (0.05, (0.3, 0.1, 0.3)), (0.4, (1.9, 0.22, 1.9)),
                                   (0.9, AN)], "LINEAR"))
    return {"goc": "DuaHieuUng", "phan": ps, "anim": {"vo": ray}}


def hieu_ung_trau():
    """Trâu điên nhìn về −Z; animation "chay" (6 nhịp × 0.5 s): thân nảy, bốn chân đảo nhịp phi."""
    toi, sung = (0.24, 0.16, 0.12, 1), (0.93, 0.88, 0.75, 1)
    ps = [phan("Than", "Box", {"size": [1.0, 0.85, 1.75]}, toi, vt=(0, 1.1, 0.1)),
          phan("Vai", "Sphere", {"radius": 0.52, "height": 1.04}, toi, vt=(0, 1.3, -0.5)),
          phan("Dau", "Box", {"size": [0.62, 0.55, 0.72]}, (0.3, 0.2, 0.15, 1),
               vt=(0, 1.15, -1.2)),
          phan("Mom", "Box", {"size": [0.46, 0.3, 0.26]}, (0.75, 0.68, 0.62, 1),
               vt=(0, 1.0, -1.6)),
          phan("SungT", "Cylinder", {"top_radius": 0.02, "bottom_radius": 0.09, "height": 0.7,
                                     "radial_segments": 10}, sung, vt=(-0.5, 1.55, -1.1),
               xoay=(0, 0, 1.0)),
          phan("SungP", "Cylinder", {"top_radius": 0.02, "bottom_radius": 0.09, "height": 0.7,
                                     "radial_segments": 10}, sung, vt=(0.5, 1.55, -1.1),
               xoay=(0, 0, -1.0)),
          phan("MatT", "Sphere", {"radius": 0.06, "height": 0.12}, (1, 0.1, 0.1, 1),
               vt=(-0.2, 1.3, -1.52), emission=[1, 0.1, 0.1], emission_energy_multiplier=2.0),
          phan("MatP", "Sphere", {"radius": 0.06, "height": 0.12}, (1, 0.1, 0.1, 1),
               vt=(0.2, 1.3, -1.52), emission=[1, 0.1, 0.1], emission_energy_multiplier=2.0),
          phan("Duoi", "Cylinder", {"top_radius": 0.03, "bottom_radius": 0.05, "height": 0.8,
                                    "radial_segments": 8}, toi, vt=(0, 1.1, 1.05),
               xoay=(-0.5, 0, 0))]
    chan = {"ChanTT": (-0.32, -0.55), "ChanTP": (0.32, -0.55), "ChanST": (-0.32, 0.75),
            "ChanSP": (0.32, 0.75)}
    for ten, (x, z) in chan.items():
        ps.append(phan(ten, "Cylinder", {"top_radius": 0.1, "bottom_radius": 0.08, "height": 0.75,
                                         "radial_segments": 10}, toi, vt=(x, 0.78, z),
                       lech=(0, -0.375, 0)))
    # Glb không đặt được loop → ghi sẵn 6 chu kỳ (3 s) cho đủ đoạn chạy của hiệu ứng.
    chu_ky = 6
    nhip = [i * 0.125 for i in range(chu_ky * 4 + 1)]
    ray = []
    for ten, (x, goc_y, z) in {"Than": (0, 1.1, 0.1), "Vai": (0, 1.3, -0.5),
                               "Dau": (0, 1.15, -1.2)}.items():
        ray.append((ten, "translation",
                    [(t, (x, goc_y + 0.07 * math.sin(t / 0.25 * math.pi), z)) for t in nhip],
                    "LINEAR"))
    for ten, pha in [("ChanTT", 1), ("ChanSP", 1), ("ChanTP", -1), ("ChanST", -1)]:
        ray.append((ten, "rotation", [(i * 0.25, (0.8 * pha * (-1) ** i, 0, 0))
                                      for i in range(chu_ky * 2 + 1)], "LINEAR"))
    return {"goc": "TrauHieuUng", "phan": ps, "anim": {"chay": ray}}


def hieu_ung_no():
    """Cục nổ: loé sáng + lửa + khói + tia lửa; animation "no" (0.8 s), cuối cùng thu về 0."""
    ps = [phan("Loi", "Sphere", {"radius": 1.0, "height": 2.0}, (1, 0.96, 0.65, 1),
               **KHOI_UNLIT),
          phan("Lua", "Sphere", {"radius": 0.85, "height": 1.7}, (1, 0.5, 0.1, 1), **KHOI_UNLIT)]
    vi_tri_khoi = [(0.7, 0.5, 0.4), (-0.6, 0.9, 0.5), (0.1, 1.2, -0.7), (-0.5, 0.4, -0.6)]
    for i, v in enumerate(vi_tri_khoi):
        ps.append(phan("Khoi%d" % (i + 1), "Sphere", {"radius": 0.7, "height": 1.4},
                       (0.22, 0.2, 0.2, 1), vt=v, roughness=1.0))
    tia = [(1, 0.8, 0), (-1, 1, 0.3), (0.2, 1.2, 1), (-0.3, 0.9, -1), (0.9, 1.1, -0.7),
           (-0.8, 0.7, 0.9)]
    for i in range(len(tia)):
        ps.append(phan("Tia%d" % (i + 1), "Box", {"size": [0.14, 0.14, 0.14]},
                       (1, 0.85, 0.3, 1), an=True, **KHOI_UNLIT))
    ray = [("Loi", "scale", [(0, (0.2, 0.2, 0.2)), (0.12, (1.5, 1.5, 1.5)), (0.35, (1, 1, 1)),
                              (0.5, AN)], "LINEAR"),
           ("Lua", "scale", [(0, (0.1, 0.1, 0.1)), (0.2, (1.7, 1.7, 1.7)), (0.6, AN)], "LINEAR")]
    for i, v in enumerate(vi_tri_khoi):
        n = "Khoi%d" % (i + 1)
        ray += [(n, "scale", [(0, AN), (0.08, (0.4, 0.4, 0.4)), (0.5, (1.25, 1.25, 1.25)),
                              (0.8, AN)], "LINEAR"),
                (n, "translation", [(0, tuple(np.array(v) * 0.3)),
                                    (0.8, tuple(np.array(v) * 1.5 + [0, 0.6, 0]))], "LINEAR")]
    for i, h in enumerate(tia):
        n = "Tia%d" % (i + 1)
        h = np.array(h) / np.linalg.norm(h)
        ray += [(n, "scale", [(0, AN), (0.02, V1), (0.5, V1), (0.7, AN)], "LINEAR"),
                (n, "translation", [(0, V0), (0.3, tuple(h * 2.0 + [0, 0.5, 0])),
                                    (0.7, tuple(h * 2.6 - [0, 0.5, 0]))], "LINEAR"),
                (n, "rotation", [(0, V0), (0.7, (4.0, 3.0, 2.0))], "LINEAR")]
    return {"goc": "NoHieuUng", "phan": ps, "anim": {"no": ray}}


def hieu_ung_dong_xu():
    """Đồng xu vàng; animation "quay" (5 vòng × 0.5 s) quanh trục đứng."""
    ps = [phan("Xu", "Cylinder", {"top_radius": 0.28, "bottom_radius": 0.28, "height": 0.07,
                                  "radial_segments": 24}, (1, 0.8, 0.15, 1),
               xoay=(math.pi / 2, 0, 0), metallic=0.8, roughness=0.3, emission=[0.6, 0.4, 0.0],
               emission_energy_multiplier=0.8)]
    return {"goc": "DongXuHieuUng", "phan": ps,
            "anim": {"quay": [("Goc", "rotation", xoay_y(0, 2.5, 5), "LINEAR")]}}


MO_HINH_HIEU_UNG = {"dua_hieu_ung": hieu_ung_dua, "trau_hieu_ung": hieu_ung_trau,
                    "no_bung": hieu_ung_no, "dong_xu": hieu_ung_dong_xu}


def dung_hieu_ung(ten, mo_ta):
    glb = Glb()
    glb.node({"name": mo_ta["goc"], "children": [1]})
    goc_trong = glb.node({"name": "Goc", "children": []})
    chi_so = {"Goc": goc_trong}
    for k in mo_ta["phan"]:
        T, R, S = tach_trs(k["transform"])
        bien = None
        if k.get("lech"):
            bien = np.eye(4)
            bien[:3, 3] = k["lech"]
        v, n, i = dung_luoi(k["loai"], k["tham_so"], bien)
        lu = glb.luoi(k["ten"], v, n, i, glb.vat_lieu(k["ten"], k["vat_lieu"]))
        chi_so[k["ten"]] = glb.node({"name": k["ten"], "mesh": lu, "translation": T,
                                     "rotation": R.tolist(),
                                     "scale": [0, 0, 0] if k.get("an") else S.tolist()})
    glb.g["nodes"][goc_trong]["children"] = [c for c in chi_so.values() if c != goc_trong]
    for ten_anim, ray in mo_ta["anim"].items():
        glb.anim(ten_anim, ray, chi_so)
    os.makedirs(THU_MUC_HIEU_UNG, exist_ok=True)
    glb.luu(os.path.join(THU_MUC_HIEU_UNG, ten + ".glb"))


def main():
    nguon = json.load(open(os.path.join(THU_MUC, "nguon.json"), encoding="utf-8"))
    for mon in sorted(nguon):
        dung_mon(mon, nguon[mon])
        print("ok", mon)
    for ten, f in MO_HINH_HIEU_UNG.items():
        dung_hieu_ung(ten, f())
        print("ok hieu_ung", ten)


if __name__ == "__main__":
    main()
