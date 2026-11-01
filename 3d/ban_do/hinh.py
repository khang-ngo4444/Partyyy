"""Khối hình numpy và bộ ghi .glb cho đảo bàn party.

Mỗi `Hinh` là lưới tam giác: đỉnh, pháp tuyến, màu (RGBA tuyến tính), UV tuỳ chọn.
Chiều quay tam giác: ngược kim đồng hồ nhìn từ ngoài vào (giống glTF/Godot).
"""
import json
import struct

import numpy as np

TAU = np.pi * 2.0


def mau(hex_mau, a=1.0):
    """'#rrggbb' sRGB sang RGBA tuyến tính."""
    h = hex_mau.lstrip("#")
    c = np.array([int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4)])
    tuyen_tinh = np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)
    return np.array([*tuyen_tinh, a])


def bien_doi(vi_tri=(0, 0, 0), xoay_y=0.0, ty_le=1.0, xoay_x=0.0, xoay_z=0.0):
    """Ma trận 4x4: tỉ lệ, rồi xoay Z, X, Y, rồi tịnh tiến."""
    t = np.broadcast_to(np.asarray(ty_le, float), (3,))
    cy, sy = np.cos(xoay_y), np.sin(xoay_y)
    cx, sx = np.cos(xoay_x), np.sin(xoay_x)
    cz, sz = np.cos(xoay_z), np.sin(xoay_z)
    ry = np.array([[cy, 0, sy], [0, 1, 0], [-sy, 0, cy]])
    rx = np.array([[1, 0, 0], [0, cx, -sx], [0, sx, cx]])
    rz = np.array([[cz, -sz, 0], [sz, cz, 0], [0, 0, 1]])
    m = np.eye(4)
    m[:3, :3] = ry @ rx @ rz @ np.diag(t)
    m[:3, 3] = vi_tri
    return m


def phap_tuyen(v, i):
    """Pháp tuyến mịn, trọng số theo diện tích."""
    n = np.zeros_like(v)
    mat = np.cross(v[i[:, 1]] - v[i[:, 0]], v[i[:, 2]] - v[i[:, 0]])
    for k in range(3):
        np.add.at(n, i[:, k], mat)
    return n / np.maximum(np.linalg.norm(n, axis=1, keepdims=True), 1e-9)


class Hinh:
    def __init__(self, v, i, n=None, c=None, uv=None):
        self.v = np.asarray(v, np.float32)
        self.i = np.asarray(i, np.uint32).reshape(-1, 3)
        self.n = phap_tuyen(self.v, self.i.astype(np.int64)) if n is None else np.asarray(n, np.float32)
        self.c = np.ones((len(self.v), 4), np.float32) if c is None else np.asarray(c, np.float32)
        self.uv = None if uv is None else np.asarray(uv, np.float32)

    def to(self, m):
        """Tô một màu, hoặc giữ màu đỉnh nhân thêm."""
        c = self.c * np.asarray(m, np.float32)
        return Hinh(self.v, self.i, self.n, c, self.uv)

    def doi_mau(self, m):
        return Hinh(self.v, self.i, self.n, np.tile(np.asarray(m, np.float32), (len(self.v), 1)), self.uv)

    def duoi(self, m):
        """Áp ma trận 4x4."""
        v = self.v @ m[:3, :3].T + m[:3, 3]
        n = self.n @ np.linalg.inv(m[:3, :3])
        n = n / np.maximum(np.linalg.norm(n, axis=1, keepdims=True), 1e-9)
        return Hinh(v, self.i, n, self.c, self.uv)

    def toi_day(self, day=0.55):
        """Nền tối dần xuống chân vật: giả ambient occlusion."""
        y = self.v[:, 1]
        t = (y - y.min()) / max(float(np.ptp(y)), 1e-5)
        c = self.c.copy()
        c[:, :3] *= (day + (1.0 - day) * np.clip(t * 1.6, 0.0, 1.0))[:, None]
        return Hinh(self.v, self.i, self.n, c, self.uv)


def ghep(ds):
    """Gộp nhiều Hinh thành một."""
    ds = list(ds)
    lech, dem = [], 0
    for h in ds:
        lech.append(h.i + dem)
        dem += len(h.v)
    co_uv = all(h.uv is not None for h in ds)
    return Hinh(np.concatenate([h.v for h in ds]), np.concatenate(lech),
            np.concatenate([h.n for h in ds]), np.concatenate([h.c for h in ds]),
            np.concatenate([h.uv for h in ds]) if co_uv else None)


# ───────────────────────────── khối cơ bản ─────────────────────────────


def luoi_hang(hang, khep=True):
    """Nối hàng điểm (m hàng × n điểm) thành tam giác. Hàng từ dưới lên, điểm theo góc tăng."""
    m, n = hang.shape[:2]
    cuoi = n if khep else n - 1
    j = np.arange(cuoi)
    j2 = (j + 1) % n
    tam = []
    for r in range(m - 1):
        a, b = r * n + j, r * n + j2
        c, d = a + n, b + n
        tam.append(np.stack([a, b, c], 1))
        tam.append(np.stack([b, d, c], 1))
    return np.concatenate(tam), hang.reshape(-1, 3)


def tien(profile, n=24, mau_hang=None, mau_goc=None):
    """Tiện tròn: `profile` [(bán kính, y)...] từ dưới lên. Mịn dọc theo vòng."""
    p = np.asarray(profile, float)
    a = np.linspace(0, TAU, n, endpoint=False)
    hang = np.stack([np.outer(p[:, 0], np.sin(a)), np.repeat(p[:, 1:2], n, 1),
            np.outer(p[:, 0], np.cos(a))], 2)
    i, v = luoi_hang(hang)
    c = np.ones((len(v), 4))
    if mau_hang is not None:
        c = np.repeat(np.asarray(mau_hang, float), n, 0)
    if mau_goc is not None:
        c = c * np.tile(np.asarray(mau_goc(a), float), (len(p), 1))
    return Hinh(v, i, c=c)


def nap(r, y, n=24, len_tren=True):
    """Mặt tròn phẳng để bít đầu khối tiện."""
    a = np.linspace(0, TAU, n, endpoint=False)
    v = np.vstack([[0, y, 0], np.stack([np.sin(a) * r, np.full(n, y), np.cos(a) * r], 1)])
    j = np.arange(n)
    i = np.stack([np.zeros(n, int), 1 + j, 1 + (j + 1) % n], 1)
    if not len_tren:
        i = i[:, [0, 2, 1]]
    return Hinh(v, i)


_MAT_HOP = (
    ((1, 0, 0), (0, 0, -1), (0, 1, 0)), ((-1, 0, 0), (0, 0, 1), (0, 1, 0)),
    ((0, 1, 0), (1, 0, 0), (0, 0, -1)), ((0, -1, 0), (1, 0, 0), (0, 0, 1)),
    ((0, 0, 1), (1, 0, 0), (0, 1, 0)), ((0, 0, -1), (-1, 0, 0), (0, 1, 0)))


def hop(sx, sy, sz, bo=0.0):
    """Hộp tâm gốc toạ độ; `bo` > 0 thì bo tròn cạnh."""
    h = np.array([sx, sy, sz]) * 0.5
    vs, ns, ti, dem = [], [], [], 0
    for ngoai, u, w in _MAT_HOP:
        ngoai, u, w = map(lambda a: np.array(a, float), (ngoai, u, w))
        hu, hw, hn = abs(u @ h), abs(w @ h), abs(ngoai @ h)
        if bo > 0.0:
            r_u = min(bo, hu * 0.95)
            r_w = min(bo, hw * 0.95)
            lu = np.array([-hu, -hu + r_u * 0.3, -hu + r_u, hu - r_u, hu - r_u * 0.3, hu])
            lw = np.array([-hw, -hw + r_w * 0.3, -hw + r_w, hw - r_w, hw - r_w * 0.3, hw])
        else:
            lu, lw = np.array([-hu, hu]), np.array([-hw, hw])
        uu, ww = np.meshgrid(lu, lw, indexing="xy")
        q = ngoai * hn + uu[..., None] * u + ww[..., None] * w
        q = q.reshape(-1, 3)
        if bo > 0.0:
            trong = np.clip(q, -h + bo, h - bo)
            lech = q - trong
            nn = lech / np.maximum(np.linalg.norm(lech, axis=1, keepdims=True), 1e-6)
            phang = np.linalg.norm(lech, axis=1) < 1e-6
            nn[phang] = ngoai
            q = trong + nn * bo
        else:
            nn = np.tile(ngoai, (len(q), 1))
        nu, nw = len(lu), len(lw)
        for b in range(nw - 1):
            for a in range(nu - 1):
                p = dem + b * nu + a
                ti += [[p, p + 1, p + nu], [p + 1, p + nu + 1, p + nu]]
        vs.append(q)
        ns.append(nn)
        dem += len(q)
    return Hinh(np.concatenate(vs), ti, np.concatenate(ns))


_ICO_CACHE = {}


def cau_ico(chia):
    """Icosphere đơn vị (cache theo mức chia)."""
    if chia in _ICO_CACHE:
        return _ICO_CACHE[chia]
    t = (1 + 5 ** 0.5) / 2
    v = [(-1, t, 0), (1, t, 0), (-1, -t, 0), (1, -t, 0), (0, -1, t), (0, 1, t), (0, -1, -t), (0, 1, -t),
            (t, 0, -1), (t, 0, 1), (-t, 0, -1), (-t, 0, 1)]
    f = [(0, 11, 5), (0, 5, 1), (0, 1, 7), (0, 7, 10), (0, 10, 11), (1, 5, 9), (5, 11, 4), (11, 10, 2),
            (10, 7, 6), (7, 1, 8), (3, 9, 4), (3, 4, 2), (3, 2, 6), (3, 6, 8), (3, 8, 9), (4, 9, 5),
            (2, 4, 11), (6, 2, 10), (8, 6, 7), (9, 8, 1)]
    v = [np.array(p, float) / np.linalg.norm(p) for p in v]
    for _ in range(chia):
        giua, moi = {}, []

        def diem_giua(a, b):
            k = (min(a, b), max(a, b))
            if k not in giua:
                p = v[a] + v[b]
                v.append(p / np.linalg.norm(p))
                giua[k] = len(v) - 1
            return giua[k]

        for a, b, c in f:
            ab, bc, ca = diem_giua(a, b), diem_giua(b, c), diem_giua(c, a)
            moi += [(a, ab, ca), (b, bc, ab), (c, ca, bc), (ab, bc, ca)]
        f = moi
    _ICO_CACHE[chia] = (np.array(v), np.array(f))
    return _ICO_CACHE[chia]


def nhieu_cau(p, rng, tan_so=2.0, bac=4):
    """Nhiễu mượt trên mặt cầu: tổng sóng sin theo hướng ngẫu nhiên."""
    y = np.zeros(len(p))
    f, b = tan_so, 1.0
    for _ in range(bac):
        for _k in range(3):
            d = rng.normal(size=3)
            d /= np.linalg.norm(d)
            y += np.sin(p @ d * f + rng.uniform(0, TAU)) * b
        f *= 2.1
        b *= 0.5
    return y / 3.0


def cuc(rng, chia=2, nhieu=0.25, tan_so=2.2, det=(1, 1, 1), bac=4):
    """Khối tròn sần: đá, tán lá, mây."""
    p, f = cau_ico(chia)
    r = 1.0 + nhieu * nhieu_cau(p, rng, tan_so, bac)
    v = p * r[:, None] * np.asarray(det)
    return Hinh(v, f)


def ong(duong, ban_kinh, n=8, mau_dau=None, mau_cuoi=None):
    """Ống mịn dọc đường cong, khung truyền song song."""
    d = np.asarray(duong, float)
    r = np.broadcast_to(ban_kinh, (len(d),)).astype(float)
    t = np.gradient(d, axis=0)
    t /= np.maximum(np.linalg.norm(t, axis=1, keepdims=True), 1e-9)
    gan = np.array([0.0, 0.0, 1.0]) if abs(t[0][2]) < 0.9 else np.array([1.0, 0.0, 0.0])
    x = np.cross(t[0], gan)
    x /= np.linalg.norm(x)
    a = np.linspace(0, TAU, n, endpoint=False)
    hang = []
    for k in range(len(d)):
        x = x - t[k] * (x @ t[k])
        x /= max(np.linalg.norm(x), 1e-9)
        y = np.cross(t[k], x)
        hang.append(d[k] + r[k] * (np.outer(np.cos(a), x) + np.outer(np.sin(a), y)))
    i, v = luoi_hang(np.array(hang))
    c = None
    if mau_dau is not None:
        s = np.linspace(0, 1, len(d))[:, None]
        hang_mau = np.asarray(mau_dau) * (1 - s) + np.asarray(mau_cuoi) * s
        c = np.repeat(hang_mau, n, 0)
    return Hinh(v, i, c=c)


def bang(duong, ben, rong, mau_hang=None, uv_y=None):
    """Dải phẳng dọc đường cong: `ben` là hướng ngang (n×3), `rong` là nửa chiều rộng."""
    d = np.asarray(duong, float)
    b = np.asarray(ben, float)
    r = np.broadcast_to(rong, (len(d),))[:, None]
    trai, phai = d - b * r, d + b * r
    v = np.stack([trai, phai], 1).reshape(-1, 3)
    i, j = [], np.arange(len(d) - 1)
    a0, b0 = j * 2, j * 2 + 1
    a1, b1 = a0 + 2, b0 + 2
    i = np.concatenate([np.stack([a0, a1, b0], 1), np.stack([b0, a1, b1], 1)])
    c = None if mau_hang is None else np.repeat(np.asarray(mau_hang), 2, 0)
    uv = None
    if uv_y is not None:
        uv = np.stack([np.tile([0.0, 1.0], len(d)), np.repeat(uv_y, 2)], 1)
    return Hinh(v, i, c=c, uv=uv)


def nan_duong(diem, moi_doan=8, khep=False):
    """Catmull-Rom qua các điểm."""
    p = np.asarray(diem, float)
    n = len(p)
    if khep:
        q = np.vstack([p[-1], p, p[0], p[1]])
    else:
        q = np.vstack([2 * p[0] - p[1], p, 2 * p[-1] - p[-2]])
    ra = []
    for k in range(1, len(q) - 2):
        p0, p1, p2, p3 = q[k - 1], q[k], q[k + 1], q[k + 2]
        for s in np.linspace(0, 1, moi_doan, endpoint=False):
            ra.append(0.5 * (2 * p1 + (p2 - p0) * s + (2 * p0 - 5 * p1 + 4 * p2 - p3) * s * s
                    + (3 * p1 - p0 - 3 * p2 + p3) * s ** 3))
    if not khep:
        ra.append(p[-1])
    return np.array(ra)


# ───────────────────────────── gom theo vật liệu ─────────────────────────────


class Lo:
    """Gom Hinh theo vật liệu thành một mesh nhiều surface."""

    def __init__(self):
        self.theo_vl = {}

    def them(self, vat_lieu, hinh, m=None, to=None):
        if m is not None:
            hinh = hinh.duoi(m)
        if to is not None:
            hinh = hinh.to(to)
        self.theo_vl.setdefault(vat_lieu, []).append(hinh)

    def gop(self):
        return {vl: ghep(ds) for vl, ds in self.theo_vl.items()}

    def rong(self):
        return not self.theo_vl


# ───────────────────────────── ghi .glb ─────────────────────────────


def ghi_glb(duong_dan, meshes):
    """`meshes`: {tên mesh: {tên vật liệu: Hinh}}. Trả về số tam giác."""
    nhi = bytearray()
    views, acc, vl_ten = [], [], []

    def them_khoi(mang, target, kieu, comp, chuan=False, co_bien=False):
        while len(nhi) % 4:
            nhi.append(0)
        raw = mang.tobytes()
        views.append({"buffer": 0, "byteOffset": len(nhi), "byteLength": len(raw), "target": target})
        nhi.extend(raw)
        a = {"bufferView": len(views) - 1, "componentType": comp,
                "count": len(mang) if kieu != "SCALAR" else mang.size, "type": kieu}
        if chuan:
            a["normalized"] = True
        if co_bien:
            a["min"] = mang.min(0).tolist()
            a["max"] = mang.max(0).tolist()
        acc.append(a)
        return len(acc) - 1

    glb_mesh, nodes, tong = [], [], 0
    for ten, surfaces in meshes.items():
        prims = []
        for vl, h in surfaces.items():
            if vl not in vl_ten:
                vl_ten.append(vl)
            mau_u8 = (np.clip(h.c, 0, 1) * 255 + 0.5).astype(np.uint8)
            thuoc = {"POSITION": them_khoi(h.v.astype(np.float32), 34962, "VEC3", 5126, co_bien=True),
                    "NORMAL": them_khoi(h.n.astype(np.float32), 34962, "VEC3", 5126),
                    "COLOR_0": them_khoi(mau_u8, 34962, "VEC4", 5121, chuan=True)}
            if h.uv is not None:
                thuoc["TEXCOORD_0"] = them_khoi(h.uv.astype(np.float32), 34962, "VEC2", 5126)
            prims.append({"attributes": thuoc, "material": vl_ten.index(vl),
                    "indices": them_khoi(h.i.astype(np.uint32).ravel(), 34963, "SCALAR", 5125)})
            tong += len(h.i)
        glb_mesh.append({"name": ten, "primitives": prims})
        nodes.append({"name": ten, "mesh": len(glb_mesh) - 1})
    while len(nhi) % 4:
        nhi.append(0)
    goc = {"asset": {"version": "2.0", "generator": "3d/ban_do/tao_ban_do.py"}, "scene": 0,
            "scenes": [{"nodes": list(range(len(nodes)))}], "nodes": nodes, "meshes": glb_mesh,
            "materials": [{"name": t} for t in vl_ten], "accessors": acc, "bufferViews": views,
            "buffers": [{"byteLength": len(nhi)}]}
    js = json.dumps(goc, separators=(",", ":")).encode()
    js += b" " * (-len(js) % 4)
    with open(duong_dan, "wb") as f:
        f.write(struct.pack("<III", 0x46546C67, 2, 28 + len(js) + len(nhi)))
        f.write(struct.pack("<II", len(js), 0x4E4F534A) + js)
        f.write(struct.pack("<II", len(nhi), 0x004E4942) + nhi)
    return tong
