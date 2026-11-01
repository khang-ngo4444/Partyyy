"""Địa hình đảo núi lửa: heightfield, sông, đường đá nối đúng vị trí các ô trong `ban_party.tscn`."""
import re

import numpy as np
from scipy.spatial import cKDTree

from hinh import (Hinh, Lo, TAU, bang, bien_doi, cuc, ghep, hop, mau, nan_duong, ong, tien)

MUC_NUOC = -4.0
Y_DUONG = 3.0
BUOC_LUOI = 0.35
NUA_CANH = 72.0
SO_KHOI_DAT = 6
SO_KHU = 8
NUA_KHU = 64.0

# tên: (x, z, bán kính mặt bằng, cao độ)
DIA_DIEM = {
    "hai_dang": (45.0, -33.0, 7.0, 9.0),
    "cang": (43.0, 9.0, 8.5, 3.0),
    "hoi_cho": (-2.0, 37.0, 11.0, 3.0),
    "den_thap": (-46.0, -5.0, 10.0, 5.5),
    "vinh_cuop": (-12.0, -39.0, 7.0, 1.6),
    "coi_xay_tay": (-37.0, 25.0, 4.5, 5.5),
    "coi_xay_dong": (31.0, 31.0, 4.0, 5.0),
    "lang_nam": (19.0, 35.0, 5.5, 3.2),
}
# Bờ cát: (góc atan2(z, x) quanh đảo, nửa độ rộng góc).
BO_CAT = ((0.3, 0.55), (1.65, 0.6), (-1.85, 0.5), (2.75, 0.3))
# Sông: chạy giữa hai cặp ô liền kề của vòng trong rồi vòng ngoài.
SONG_QUA_O = (((54, 55), (1, 2)), ((46, 47), (20, 21)), ((50, 51), (31, 32)))


def doc_o(duong_scene):
    """{số ô: (x, z)} từ scene bàn; số ô theo tên node O_n."""
    txt = open(duong_scene, encoding="utf-8").read()
    ra = {}
    for khoi in re.split(r"(?=\[node )", txt):
        ten = re.match(r'\[node name="O_(\d+)"', khoi)
        if ten is None:
            continue
        # Godot lưu `transform` khi node có xoay, `position` khi không.
        bien = re.search(r"transform = Transform3D\(([^)]*)\)", khoi)
        if bien is not None:
            so = [float(v) for v in bien.group(1).split(",")]
            ra[int(ten.group(1))] = np.array([so[9], so[11]])
        else:
            vi_tri = re.search(r"position = Vector3\(([^)]*)\)", khoi)
            so = [float(v) for v in vi_tri.group(1).split(",")]
            ra[int(ten.group(1))] = np.array([so[0], so[2]])
    return ra


def _mem(a, b, x):
    t = np.clip((x - a) / (b - a), 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)


def nhieu(x, z, tan_so, hat=0):
    """Nhiễu giá trị 2D mịn trong [0, 1]."""
    rng = np.random.default_rng(hat)
    bang_ngau = rng.random((256, 256))
    px, pz = x * tan_so + hat * 17.3, z * tan_so - hat * 9.1
    ix, iz = np.floor(px).astype(int), np.floor(pz).astype(int)
    fx, fz = px - ix, pz - iz
    ux, uz = fx * fx * (3 - 2 * fx), fz * fz * (3 - 2 * fz)
    g = lambda a, b: bang_ngau[a % 256, b % 256]
    tren = g(ix, iz) * (1 - ux) + g(ix + 1, iz) * ux
    duoi = g(ix, iz + 1) * (1 - ux) + g(ix + 1, iz + 1) * ux
    return tren * (1 - uz) + duoi * uz


def fbm(x, z, tan_so, bac=4, hat=0):
    y, b, f, tong = 0.0, 1.0, tan_so, 0.0
    for k in range(bac):
        y = y + nhieu(x, z, f, hat + k * 31) * b
        tong += b
        f *= 2.03
        b *= 0.5
    return y / tong


def gon_song(x, z, tan_so, bac=4, hat=0):
    """Nhiễu có sống đá sắc."""
    y, b, f, tong = 0.0, 1.0, tan_so, 0.0
    for k in range(bac):
        y = y + (1.0 - np.abs(nhieu(x, z, f, hat + k * 53) * 2.0 - 1.0)) * b
        tong += b
        f *= 2.1
        b *= 0.5
    return y / tong


class DiaHinh:
    """Lưới cao độ và các trường khoảng cách để đặt vật."""

    def __init__(self, cac_o):
        self.o = cac_o
        self.toa_do = np.arange(-NUA_CANH, NUA_CANH + BUOC_LUOI * 0.5, BUOC_LUOI)
        self.X, self.Z = np.meshgrid(self.toa_do, self.toa_do)
        self.duong = self._duong_vong()
        self.song = self._tao_song()
        self.cay_duong = cKDTree(np.vstack(self.duong))
        self.cay_o = cKDTree(np.array(list(cac_o.values())))
        self.cay_song = cKDTree(np.vstack([s[:, [0, 2]] for s in self.song]))
        self.t_bo = None
        self.H = self._cao_do()
        gz, gx = np.gradient(self.H, BUOC_LUOI)
        self.gx, self.gz = gx, gz
        self.doc = np.hypot(gx, gz)
        self.kiem_tra()

    def _duong_vong(self):
        ngoai = [self.o[i] for i in range(40)]
        trong_so = [4, 40, 41, 42, 43, 14, 44, 45, 46, 47, 24, 48, 49, 50, 51, 34, 52, 53, 54, 55]
        return [nan_duong(ngoai, 10, khep=True), nan_duong([self.o[i] for i in trong_so], 18, khep=True)]

    def _truong_bo(self, x, z):
        """s < 1 là đất liền; hợp mềm giữa elip chính và các mũi đất."""
        s = np.hypot(x / 47.0, z / 41.0)
        for ten, (cx, cz, r, _y) in DIA_DIEM.items():
            mui = np.hypot(x - cx, z - cz) / (r + 9.0)
            k = 0.16
            h = np.clip(0.5 + 0.5 * (mui - s) / k, 0.0, 1.0)
            s = mui * (1 - h) + s * h - k * h * (1 - h)
        return s + (fbm(x, z, 0.045, 4, 3) - 0.5) * 0.24

    def _tao_song(self):
        """Mỗi sông: mảng (x, y mặt nước, z) từ suối trên sườn núi ra tới biển."""
        ds = []
        for (trong, ngoai) in SONG_QUA_O:
            a = (self.o[trong[0]] + self.o[trong[1]]) * 0.5
            b = (self.o[ngoai[0]] + self.o[ngoai[1]]) * 0.5
            huong = (b - a) / np.linalg.norm(b - a)
            suoi = a / np.linalg.norm(a) * 9.5
            chan_nui = a * 0.68
            bien = b + huong * 2.0
            while self._truong_bo(np.array([bien[0]]), np.array([bien[1]]))[0] < 0.96:
                bien = bien + huong
            mep = bien.copy()
            xa = bien + huong * 6.0
            cong = nan_duong([suoi, chan_nui, a, (a + b) * 0.5 + np.array([-huong[1], huong[0]]) * 0.6, b, mep], 16)
            cong = np.vstack([cong, mep + huong * 2.2, xa])
            dai = np.concatenate([[0.0], np.cumsum(np.linalg.norm(np.diff(cong, axis=0), axis=1))])
            s_a = dai[16 * 2]
            s_mep = dai[-3]
            y = np.interp(dai, [0.0, s_a * 0.32, s_a * 0.42, s_a, s_mep, dai[-2], dai[-1]],
                    [12.5, 7.5, 3.1, 1.75, 1.6, MUC_NUOC - 0.2, MUC_NUOC - 0.2])
            ds.append(np.column_stack([cong[:, 0], y, cong[:, 1]]))
        return ds

    def _cao_do(self):
        x, z = self.X, self.Z
        s = self._truong_bo(x, z)
        t = s - 1.0
        self.t_bo = t
        goc = np.arctan2(z, x)
        cat = np.zeros_like(x)
        for g, rong in BO_CAT:
            lech = np.abs((goc - g + np.pi) % TAU - np.pi)
            cat = np.maximum(cat, 1.0 - _mem(rong * 0.6, rong, lech))
        cat = np.clip(cat + (fbm(x, z, 0.08, 3, 9) - 0.5) * 0.5, 0.0, 1.0)
        self.mat_cat = cat
        vach = np.interp(t, [-0.05, 0.0, 0.055, 0.1, 0.3, 0.7], [3.0, 2.4, MUC_NUOC - 3.2, -8.0, -10.0, -28.0])
        bai = np.interp(t, [-0.24, -0.1, 0.0, 0.17, 0.32, 0.7], [3.0, 0.8, MUC_NUOC, -6.0, -9.5, -28.0])
        h = vach * (1 - cat) + bai * cat
        # Vách đá phân tầng, chỉ tác dụng trên phần vách.
        tang = np.round(h / 1.7) * 1.7
        mat_vach = (1 - cat) * _mem(-0.04, 0.0, t) * (1 - _mem(0.05, 0.12, t))
        h = h * (1 - mat_vach * 0.55) + tang * mat_vach * 0.55
        h += (gon_song(x, z, 0.5, 3, 12) - 0.6) * 1.4 * mat_vach
        # Đồi thoải trên đất liền.
        trong_dat = _mem(-0.07, -0.24, t)
        h += (fbm(x, z, 0.07, 4, 21) - 0.45) * 3.4 * trong_dat
        h += (fbm(x, z, 0.5, 3, 22) - 0.5) * 0.3 * trong_dat
        for cx, cz, r, y in DIA_DIEM.values():
            d = np.hypot(x - cx, z - cz)
            w = 1.0 - _mem(r * 0.9, r * 1.6, d)
            h = h * (1 - w) + y * w
        h = self._them_nui(x, z, h)
        # San phẳng đường và ô.
        d_duong = self.cay_duong.query(np.column_stack([x.ravel(), z.ravel()]))[0].reshape(x.shape)
        self.d_duong = d_duong
        w = 1.0 - _mem(1.25, 3.6, d_duong)
        h = h * (1 - w) + Y_DUONG * w
        h = self._khoet_song(x, z, h)
        d_o = self.cay_o.query(np.column_stack([x.ravel(), z.ravel()]))[0].reshape(x.shape)
        self.d_o = d_o
        w = 1.0 - _mem(1.4, 2.0, d_o)
        return h * (1 - w) + Y_DUONG * w

    def _them_nui(self, x, z, h):
        r = np.hypot(x, z)
        goc = np.arctan2(z, x)
        lech = (fbm(x, z, 0.14, 3, 41) - 0.5) * 1.8
        r_m = np.maximum(r + lech, 0.0)
        nui = 49.0 * np.exp(-(r_m / 8.0) ** 1.9)
        gan = gon_song(np.cos(goc) * 3.2 + r_m * 0.09, np.sin(goc) * 3.2 + r_m * 0.09, 1.1, 4, 44)
        nui = nui * (0.72 + 0.56 * gan)
        tang = np.round(nui / 2.2) * 2.2
        nui = nui * 0.55 + tang * 0.45
        # Chỉ nâng đất quanh chân núi; phần còn lại giữ nguyên bờ biển.
        y = h + np.maximum(3.0 + nui - h, 0.0) * _mem(0.02, 0.6, nui)
        # Miệng núi lửa.
        mieng = _mem(4.9, 3.1, r_m)
        vanh = 35.0 + (fbm(x, z, 0.5, 2, 47) - 0.5) * 3.0
        y = np.where(r_m < 6.5, np.minimum(y, vanh + 2.5), y)
        y = y * (1 - mieng) + 32.0 * mieng
        # Không cho sườn chạm camera bám ô phía bắc (camera cao 11.1 ở bán kính ~10.5).
        tran = 9.0 + _mem(10.6, 7.0, r) * 40.0
        return np.minimum(y, tran)

    def _khoet_song(self, x, z, h):
        pts = np.vstack([s[:, [0, 2]] for s in self.song])
        y_nuoc = np.concatenate([s[:, 1] for s in self.song])
        d, chi = cKDTree(pts).query(np.column_stack([x.ravel(), z.ravel()]))
        d = d.reshape(x.shape)
        day = y_nuoc[chi].reshape(x.shape) - 0.75
        self.d_song = d
        w = 1.0 - _mem(0.95, 2.15, d)
        return np.minimum(h, h * (1 - w) + day * w)

    def kiem_tra(self):
        for so, p in self.o.items():
            y = self.cao(p[0], p[1])
            assert abs(y - Y_DUONG) < 0.12, f"O_{so}: mặt đất {y:.2f} lệch khỏi đường"
            d, _ = self.cay_song.query(p)
            assert d > 1.4, f"O_{so} nằm sát sông: {d:.2f}"
        for ten, p in (("bac", (0.0, -10.5)), ("bac_tay", (-6.0, -10.0)), ("bac_dong", (4.0, -11.0))):
            assert self.cao(*p) < 10.5, f"Sườn núi chạm camera ở {ten}: {self.cao(*p):.2f}"

    def cao(self, x, z):
        """Cao độ nội suy song tuyến."""
        fx = (np.asarray(x) + NUA_CANH) / BUOC_LUOI
        fz = (np.asarray(z) + NUA_CANH) / BUOC_LUOI
        n = self.H.shape[0] - 2
        ix = np.clip(np.floor(fx).astype(int), 0, n)
        iz = np.clip(np.floor(fz).astype(int), 0, n)
        ux, uz = np.clip(fx - ix, 0, 1), np.clip(fz - iz, 0, 1)
        return (self.H[iz, ix] * (1 - ux) + self.H[iz, ix + 1] * ux) * (1 - uz) \
                + (self.H[iz + 1, ix] * (1 - ux) + self.H[iz + 1, ix + 1] * ux) * uz

    def lay_truong(self, truong, x, z):
        ix = np.clip(((np.asarray(x) + NUA_CANH) / BUOC_LUOI).astype(int), 0, self.H.shape[1] - 1)
        iz = np.clip(((np.asarray(z) + NUA_CANH) / BUOC_LUOI).astype(int), 0, self.H.shape[0] - 1)
        return truong[iz, ix]

    def khoi_dat(self):
        """Chia lưới thành các mesh; bỏ phần chìm sâu không nhìn thấy."""
        H = self.H
        nor = np.dstack([-self.gx, np.ones_like(H), -self.gz])
        nor /= np.linalg.norm(nor, axis=2, keepdims=True)
        mau_tron = self._tron_vat_lieu()
        n = H.shape[0]
        ra = {}
        bien = np.linspace(0, n - 1, SO_KHOI_DAT + 1).astype(int)
        for a in range(SO_KHOI_DAT):
            for b in range(SO_KHOI_DAT):
                z0, z1, x0, x1 = bien[a], bien[a + 1], bien[b], bien[b + 1]
                Hc = H[z0:z1 + 1, x0:x1 + 1]
                if Hc.max() < -17.0:
                    continue
                nz, nx = Hc.shape
                v = np.dstack([self.X[z0:z1 + 1, x0:x1 + 1], Hc, self.Z[z0:z1 + 1, x0:x1 + 1]]).reshape(-1, 3)
                p = np.arange(nz * nx).reshape(nz, nx)
                t0 = p[:-1, :-1].ravel()
                t1 = p[:-1, 1:].ravel()
                t2 = p[1:, :-1].ravel()
                t3 = p[1:, 1:].ravel()
                tri = np.concatenate([np.stack([t0, t2, t1], 1), np.stack([t1, t2, t3], 1)])
                giu = v[tri, 1].max(axis=1) > -18.0
                ra[f"dat_{a}_{b}"] = {"dat": Hinh(v, tri[giu], nor[z0:z1 + 1, x0:x1 + 1].reshape(-1, 3),
                        mau_tron[z0:z1 + 1, x0:x1 + 1].reshape(-1, 4))}
        return ra

    def _tron_vat_lieu(self):
        """Trộn trong màu đỉnh: R cát, G cỏ, B đá, A đất đường."""
        H, x, z = self.H, self.X, self.Z
        nh = (fbm(x, z, 0.3, 3, 61) - 0.5) * 1.6
        cat = (self.mat_cat * _mem(1.9, 0.4, H + nh)) + _mem(MUC_NUOC + 2.2, MUC_NUOC + 0.8, H + nh)
        cat = np.clip(cat, 0, 1)
        da = _mem(0.62, 1.15, self.doc + nh * 0.25)
        r = np.hypot(x, z)
        da = np.maximum(da, _mem(13.0, 8.5, r + nh))
        dat_duong = 1.0 - _mem(0.9, 1.9, self.d_duong + nh * 0.3)
        dat_duong = np.maximum(dat_duong, (1.0 - _mem(1.2, 1.9, self.d_song)) * 0.7)
        co = np.ones_like(H)
        w = np.dstack([cat * (1 - da), co * (1 - cat) * (1 - da), da, dat_duong])
        w[..., :3] /= np.maximum(w[..., :3].sum(2, keepdims=True), 1e-4)
        return w


# ───────────────────────────── đường đá, cầu, sông ─────────────────────────────


def _o_khu(x, z):
    a = int(np.clip((x + NUA_KHU) / (2 * NUA_KHU) * SO_KHU, 0, SO_KHU - 1))
    b = int(np.clip((z + NUA_KHU) / (2 * NUA_KHU) * SO_KHU, 0, SO_KHU - 1))
    return a, b


def _vien(rng):
    """Viên đá lát: vòm dẹt."""
    return tien([(0.98, 0.0), (1.0, 0.42), (0.74, 0.86), (0.28, 1.0), (0.0, 1.0)], 7).toi_day(0.6)


def lat_duong(dh, rng):
    """Đá lát, bó vỉa, bệ ô, cầu. Trả {(a, b): Lo} theo khu."""
    khu = {}
    lo_khu = lambda x, z: khu.setdefault(_o_khu(x, z), Lo())
    vien = _vien(rng)
    be = cuc(np.random.default_rng(7), 1, 0.12, 2.0)
    bang_da = [mau(c) for c in ("#b6a58c", "#a1917b", "#c9b89d", "#938573", "#bfa98a")]
    cau_vung = []
    for duong in dh.duong:
        cau_vung += _lat_mot_vong(dh, duong, rng, lo_khu, vien, be, bang_da)
    for p1, p2 in cau_vung:
        _dung_cau(dh, p1, p2, lo_khu(p1[0], p1[2]), rng)
    for p in dh.o.values():
        _be_o(p, lo_khu(p[0], p[1]), be, rng)
    return khu


def _lat_mot_vong(dh, duong, rng, lo_khu, vien, be, bang_da):
    """Đặt đá dọc đường; đoạn qua sông để dành làm cầu."""
    dong = np.vstack([duong, duong[0]])
    doan = np.linalg.norm(np.diff(dong, axis=0), axis=1)
    dai = np.concatenate([[0.0], np.cumsum(doan)])
    cau_vung, trong_cau, dau_cau = [], False, None
    s = 0.0
    while s < dai[-1]:
        p = np.array([np.interp(s, dai, dong[:, 0]), np.interp(s, dai, dong[:, 1])])
        tiep = np.array([np.interp(s + 0.1, dai, dong[:, 0]), np.interp(s + 0.1, dai, dong[:, 1])])
        f = (tiep - p) / max(np.linalg.norm(tiep - p), 1e-6)
        ben = np.array([f[1], -f[0]])
        goc = np.arctan2(f[0], f[1])
        d_song = dh.cay_song.query(p)[0]
        d_o = dh.cay_o.query(p)[0]
        qua_song = d_song < 1.9
        if qua_song and not trong_cau:
            trong_cau, dau_cau = True, p
        elif trong_cau and not qua_song:
            trong_cau = False
            cau_vung.append((np.array([dau_cau[0], 3.0, dau_cau[1]]), np.array([p[0], 3.0, p[1]])))
        if not qua_song:
            lo = lo_khu(p[0], p[1])
            if d_o > 1.3:
                for lech in (-0.62, 0.0, 0.62):
                    q = p + ben * (lech + rng.uniform(-0.05, 0.05)) + f * rng.uniform(-0.05, 0.05)
                    r = rng.uniform(0.25, 0.32)
                    m = bien_doi((q[0], Y_DUONG + 0.01, q[1]), rng.uniform(0, TAU), (r, r * 0.38, r))
                    lo.them("da", vien, m, bang_da[rng.integers(len(bang_da))])
            if d_o > 1.7 and int(s / 0.62) % 2 == 0:
                for phia in (-1.0, 1.0):
                    q = p + ben * phia * 1.12
                    m = bien_doi((q[0], Y_DUONG + 0.03, q[1]), goc, (rng.uniform(.19, .27), rng.uniform(.11, .18), .3))
                    lo.them("da", be, m, mau("#8f8678"))
        s += 0.62
    return cau_vung


def _dung_cau(dh, a, b, lo, rng):
    """Cầu gỗ vòm qua sông."""
    mau_go = [mau(c) for c in ("#8a5a33", "#9c6a3e", "#7b4e2b", "#a87747")]
    mau_cot = mau("#5e3c20")
    huong = b - a
    dai = np.linalg.norm(huong)
    f = huong / max(dai, 1e-6)
    ben = np.array([f[2], 0.0, -f[0]])
    goc = np.arctan2(f[0], f[2])
    so_van = max(int((dai + 1.6) / 0.33), 4)
    cao_cuoi = 0.34
    for k in range(so_van):
        s = (k + 0.5) / so_van
        q = a - f * 0.8 + f * (dai + 1.6) * s
        cong = np.sin(s * np.pi) * cao_cuoi
        m = bien_doi((q[0], 3.08 + cong, q[2]), goc + rng.uniform(-0.02, 0.02), 1.0,
                xoay_x=-np.cos(s * np.pi) * cao_cuoi * np.pi / (dai + 1.6))
        lo.them("mau", hop(1.75 + rng.uniform(-.1, .1), 0.09, 0.3), m, mau_go[rng.integers(4)])
    for phia in (-1.0, 1.0):
        lan_can = []
        for k in range(9):
            s = k / 8
            q = a - f * 0.8 + f * (dai + 1.6) * s + ben * phia * 0.95
            lan_can.append((q[0], 3.68 + np.sin(s * np.pi) * cao_cuoi, q[2]))
            if k % 2 == 0:
                m = bien_doi((q[0], 3.32 + np.sin(s * np.pi) * cao_cuoi, q[2]))
                lo.them("mau", tien([(0.09, -0.4), (0.075, 0.3), (0.1, 0.36), (0.0, 0.42)], 8), m, mau_cot)
        lo.them("mau", ong(lan_can, 0.042, 6), to=mau("#a67c52"))
        for dau in (0.0, 1.0):
            q = a - f * 0.8 + f * (dai + 1.6) * dau + ben * phia * 0.95
            m = bien_doi((q[0], 2.9, q[2]), ty_le=(0.26, 0.5, 0.26))
            lo.them("da", cuc(rng, 1, 0.12), m, mau("#9b9182"))


def _be_o(p, lo, be, rng):
    """Bệ đá tròn dưới mỗi ô, viền đá cuội."""
    than = tien([(1.32, 0.0), (1.5, 0.5), (1.56, 2.72), (1.5, 2.86), (1.4, 2.92), (0.0, 2.92)], 40)
    lo.them("da", than, bien_doi((p[0], 0.0, p[1])), mau("#c9bda6"))
    for k in range(16):
        a = k / 16 * TAU + rng.uniform(-0.04, 0.04)
        m = bien_doi((p[0] + np.sin(a) * 1.62, 2.98, p[1] + np.cos(a) * 1.62), a,
                (0.27, rng.uniform(0.14, 0.2), 0.2))
        lo.them("da", be, m, mau("#8a7f6d"))


def mat_song(dh):
    """Mặt nước sông + thác. UV.y theo mét dọc dòng chảy; R màu đỉnh = độ dốc (bọt thác)."""
    ra = []
    for s in dh.song:
        f = np.gradient(s, axis=0)
        ngang = np.hypot(f[:, 0], f[:, 2])
        ben = np.column_stack([f[:, 2], np.zeros(len(s)), -f[:, 0]]) / np.maximum(ngang, 1e-6)[:, None]
        dai = np.concatenate([[0.0], np.cumsum(np.linalg.norm(np.diff(s, axis=0), axis=1))])
        doc = np.clip(np.abs(f[:, 1]) / np.maximum(ngang, 1e-4), 0.0, 1.0)
        rong = np.interp(dai, [0, dai[-1] * 0.25, dai[-1]], [0.55, 1.15, 1.3])
        c = np.column_stack([doc, np.zeros(len(s)), np.zeros(len(s)), np.ones(len(s))])
        ra.append(bang(s, ben, rong, mau_hang=c, uv_y=dai))
    return ghep(ra)


def dung_nham(dh, rng):
    """Hồ dung nham trong miệng núi + các dòng chảy xuống sườn."""
    ra = []
    tam = tien([(4.8, 33.2), (0.0, 33.2)], 40)
    uv_ho = np.column_stack([tam.v[:, 0] * 0.5, tam.v[:, 2] * 0.5])
    ra.append(Hinh(tam.v, tam.i, tam.n, tam.c, uv_ho))
    for g in (0.35, 2.2, 4.3):
        p = []
        for r in np.linspace(3.8, 11.5, 40):
            a = g + np.sin(r * 0.9 + g * 3.0) * 0.08
            x, z = np.cos(a) * r, np.sin(a) * r
            p.append((x, float(dh.cao(x, z)) + 0.12, z))
        p = np.array(p)
        f = np.gradient(p, axis=0)
        ben = np.column_stack([f[:, 2], np.zeros(len(p)), -f[:, 0]])
        ben /= np.maximum(np.linalg.norm(ben, axis=1, keepdims=True), 1e-6)
        dai = np.concatenate([[0.0], np.cumsum(np.linalg.norm(np.diff(p, axis=0), axis=1))])
        rong = np.interp(dai, [0, dai[-1] * 0.7, dai[-1]], [0.8, 0.5, 0.05])
        ra.append(bang(p, ben, rong, uv_y=dai * 0.35))
    return ghep(ra)


# ───────────────────────────── đảo xa, cột đá ─────────────────────────────


def dao_xa(rng, ban_kinh, cao, n_goc=64, n_vong=14):
    """Đảo nhỏ dạng lưới cực, mép chìm xuống biển."""
    a = np.linspace(0, TAU, n_goc, endpoint=False)
    r_t = np.linspace(0, 1, n_vong)
    hang = []
    mau_h = []
    hat = int(rng.integers(0, 9999))
    for t in r_t[::-1]:
        x, z = np.sin(a) * t * ban_kinh, np.cos(a) * t * ban_kinh
        vanh = 0.75 + 0.5 * fbm(np.sin(a) * 3 + 5, np.cos(a) * 3 + 5, 1.0, 3, hat)
        rr = t / vanh
        y = cao * (1 - _mem(0.0, 1.0, rr)) ** 1.2 * (0.7 + 0.6 * fbm(x, z, 0.2, 3, hat + 1)) + MUC_NUOC - 3.0 * _mem(0.8, 1.0, rr)
        y = np.round(y / 1.8) * 0.9 + y * 0.5
        hang.append(np.stack([x, y, z], 1))
        co = _mem(0.6, 2.5, y - MUC_NUOC) * (1 - _mem(1.0, 1.8, np.gradient(y) * 0 + rr * 1.8))
        cat = 1.0 - _mem(0.3, 1.2, y - MUC_NUOC)
        da = np.clip(1 - co - cat, 0, 1)
        mau_h.append(np.stack([cat, co, da, np.zeros_like(y)], 1))
    v, c = np.array(hang), np.array(mau_h)
    from hinh import luoi_hang
    i, pv = luoi_hang(v)
    # Hàng đi từ mép vào tâm tương đương "dưới lên" của khối tiện nên mặt quay lên trên.
    return Hinh(pv, i, c=c.reshape(-1, 4))


def cot_da(rng, cao, rong):
    """Cột đá biển có chóp cỏ."""
    than = cuc(rng, 3, 0.3, 2.6, (rong, cao * 0.5, rong), 5)
    v = than.v.copy()
    t = (v[:, 1] + cao * 0.5) / cao
    v[:, 0] *= 1.25 - 0.55 * t
    v[:, 2] *= 1.25 - 0.55 * t
    return Hinh(v, than.i)
