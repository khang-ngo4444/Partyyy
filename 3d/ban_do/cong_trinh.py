"""Các điểm nhấn quanh đảo. Hàm trả về Lo ở toạ độ đảo; phần chuyển động xuất mesh riêng ở gốc của nó."""
import numpy as np

from dia_hinh import DIA_DIEM, MUC_NUOC
from hinh import Hinh, Lo, TAU, bang, bien_doi, cuc, ghep, hop, mau, nap, nan_duong, ong, tien

DA_SANG = mau("#d8ccb4")
DA_XAM = mau("#9b9384")
GO = mau("#8a5a33")
GO_TOI = mau("#5e3c20")
VANG = mau("#f2b632")
DO = mau("#d9412f")
TRANG = mau("#f6efe0")


def _dia(ten):
    x, z, _r, y = DIA_DIEM[ten]
    return np.array([x, y, z])


def _mai_ngoi(lo, m, rong, sau, cao, mau_mai):
    """Mái dốc hai phía xếp từng hàng ngói."""
    hang = max(int(sau / 0.42), 3)
    dai = np.hypot(rong * .5, cao)
    goc = np.arctan2(cao, rong * .5)
    for phia in (-1.0, 1.0):
        for k in range(max(int(dai / 0.34), 3)):
            s = (k + .5) / max(int(dai / 0.34), 3)
            x = phia * rong * .5 * (1 - s)
            y = cao * s
            s_mau = (0.86 + (k % 2) * 0.14)
            bien = bien_doi((x, y, 0), 0.0, 1.0, xoay_z=-phia * goc)
            lo.them("mau", hop(0.4, 0.07, sau, 0.0), m @ bien, mau_mai * np.array([s_mau, s_mau, s_mau, 1.0]))
    lo.them("mau", ong([(0, cao + .03, -sau * .5), (0, cao + .03, sau * .5)], .09, 6), m, mau_mai * .7)
    return hang


def nha(lo, rng, vi_tri, goc, mau_tuong, mau_mai, rong=3.2, sau=4.0, cao=2.6):
    m = bien_doi(vi_tri, goc)
    lo.them("da", hop(rong + .35, .6, sau + .35, .08), m @ bien_doi((0, .05, 0)), DA_XAM)
    lo.them("mau", hop(rong, cao, sau, .1), m @ bien_doi((0, cao * .5 + .25, 0)), mau_tuong)
    # Đầu hồi tam giác.
    for z in (-sau * .5 + .01, sau * .5 - .01):
        n = 1.0 if z > 0 else -1.0
        v = np.array([(-rong * .5, 0, 0), (rong * .5, 0, 0), (0, rong * .42, 0)], float)
        i = [[0, 1, 2]] if n > 0 else [[0, 2, 1]]
        lo.them("mau", Hinh(v, i), m @ bien_doi((0, cao + .25, z)), mau_tuong)
    _mai_ngoi(lo, m @ bien_doi((0, cao + .25, 0)), rong + .6, sau + .7, rong * .42 + .08, mau_mai)
    # Cột gỗ góc, cửa, cửa sổ phát sáng.
    for x in (-rong * .5, rong * .5):
        for z in (-sau * .5, sau * .5):
            lo.them("mau", hop(.2, cao, .2, .03), m @ bien_doi((x, cao * .5 + .25, z)), GO_TOI)
    lo.them("mau", hop(.95, 1.65, .1, .04), m @ bien_doi((0, 1.08, sau * .5 + .03)), GO)
    lo.them("kim", cuc(rng, 1, 0).doi_mau(VANG), m @ bien_doi((.3, 1.05, sau * .5 + .1), ty_le=.06))
    for x in (-rong * .32, rong * .32):
        lo.them("mau", hop(.74, .86, .08, .02), m @ bien_doi((x, 1.75, sau * .5 + .02)), GO_TOI)
        lo.them("phat_sang", hop(.56, .68, .1), m @ bien_doi((x, 1.75, sau * .5 + .03)), mau("#ffd27a"))
    for z in (-.9, .9):
        lo.them("mau", hop(.08, .86, .74, .02), m @ bien_doi((rong * .5 + .02, 1.8, z)), GO_TOI)
        lo.them("phat_sang", hop(.1, .68, .56), m @ bien_doi((rong * .5 + .03, 1.8, z)), mau("#ffd27a"))
    # Ống khói.
    lo.them("da", hop(.5, 1.5, .5, .05), m @ bien_doi((rong * .25, cao + 1.15, -sau * .25)), mau("#a0614a"))


def _thung(lo, rng, vi_tri, r=.34, cao=.85):
    prof = [(r * .86, 0), (r, cao * .25), (r * 1.05, cao * .5), (r, cao * .75), (r * .86, cao)]
    m = bien_doi(vi_tri, rng.uniform(0, TAU))
    lo.them("mau", tien(prof, 14).doi_mau(GO), m)
    lo.them("mau", nap(r * .86, cao, 14).doi_mau(GO_TOI), m)
    for t in (.22, .78):
        y = cao * t
        lo.them("kim", tien([(r * 1.03, y - .03), (r * 1.05, y + .03)], 14).doi_mau(mau("#7c7468")), m)


def _thung_go(lo, rng, vi_tri, c=.7):
    m = bien_doi(vi_tri + np.array([0, c * .5, 0]), rng.uniform(0, TAU))
    lo.them("mau", hop(c, c, c, .025).doi_mau(mau("#a87747")), m)
    for phia in (-1, 1):
        lo.them("mau", hop(c * 1.03, c * .12, c * 1.03).doi_mau(GO_TOI), m @ bien_doi((0, phia * c * .42, 0)))


def den_duong(lo, rng, vi_tri, mau_den="#ffd27a"):
    cot = tien([(.11, 0), (.075, .12), (.05, .5), (.04, 2.1), (.07, 2.16), (.05, 2.22)], 10)
    lo.them("kim", cot.doi_mau(mau("#39352f")), bien_doi(vi_tri))
    lo.them("phat_sang", cuc(rng, 2, 0).doi_mau(mau(mau_den)), bien_doi(vi_tri + np.array([0, 2.42, 0]), ty_le=(.17, .22, .17)))
    lo.them("kim", tien([(.2, 2.6), (.05, 2.78), (0, 2.8)], 10).doi_mau(mau("#39352f")), bien_doi(vi_tri))
    lo.them("kim", nap(.2, 2.6, 10, len_tren=False).doi_mau(mau("#39352f")), bien_doi(vi_tri))


def hai_dang():
    lo = Lo()
    p = _dia("hai_dang")
    rng = np.random.default_rng(11)
    lo.them("da", cuc(rng, 3, .1, 1.6, (6.5, 2.2, 6.5)), bien_doi(p + (0, -.8, 0)), DA_XAM)
    s = np.linspace(0, 1, 25)
    r = 3.0 - s * 1.5 + .35 * np.exp(-s * 18)
    y = s * 21.0
    mau_vong = np.array([DO if int(t * 6) % 2 else TRANG for t in s])
    lo.them("mau", tien(np.column_stack([r, y]), 40, mau_hang=mau_vong), bien_doi(p))
    tang = bien_doi(p + (0, 21.0, 0))
    lo.them("mau", tien([(1.45, -.1), (2.2, .25), (2.3, .42), (0, .42)], 40).doi_mau(mau("#49423a")), tang)
    for k in range(20):
        a = k / 20 * TAU
        lo.them("kim", hop(.06, .75, .06).doi_mau(mau("#39352f")), tang @ bien_doi((np.sin(a) * 2.2, .8, np.cos(a) * 2.2)))
    lo.them("kim", tien([(2.2, 1.1), (2.24, 1.18)], 40).doi_mau(mau("#39352f")), tang)
    lo.them("phat_sang", tien([(.95, .4), (.95, 2.5)], 24).doi_mau(mau("#fff0b0")), tang)
    for k in range(8):
        a = k / 8 * TAU
        lo.them("kim", hop(.09, 2.2, .09).doi_mau(mau("#39352f")), tang @ bien_doi((np.sin(a) * 1.02, 1.45, np.cos(a) * 1.02)))
    lo.them("mau", tien([(1.42, 2.5), (1.3, 2.68), (.45, 3.5), (.16, 3.72), (.1, 4.3), (0, 4.42)], 32).doi_mau(DO), tang)
    lo.them("mau", nap(1.42, 2.5, 32, len_tren=False).doi_mau(mau("#8f2a20")), tang)
    lo.them("kim", cuc(rng, 2, 0).doi_mau(VANG), tang @ bien_doi((0, 4.5, 0), ty_le=.22))
    for k in range(6):
        y0 = 4 + k * 3
        a = k * 1.05
        for g in (a, a + .55):
            lo.them("phat_sang", hop(.1, .55, .4).doi_mau(mau("#ffd27a")),
                    bien_doi(p + (np.sin(g) * (3.02 - y0 / 21 * 1.5), y0, np.cos(g) * (3.02 - y0 / 21 * 1.5)), g + np.pi / 2))
    nha(lo, rng, p + (-5.0, 0, 3.4), .6, TRANG, mau("#b8482e"), 2.8, 3.4, 2.2)
    for k in range(5):
        a = -1.1 + k * .55
        den_duong(lo, rng, p + (np.sin(a) * 6.2, -.1, np.cos(a) * 6.2))
    return lo


def tia_den():
    """Hai tia sáng nón, xoay quanh trục Y tại gốc."""
    ds = []
    for g in (0.0, np.pi):
        s = np.linspace(0, 1, 2)
        v = tien([(.75, 0.0), (6.5, 42.0)], 16).duoi(bien_doi((0, 0, 0), g, 1.0, xoay_x=np.pi / 2))
        c = v.c.copy()
        c[:len(c) // 2, 3] = 0.55
        c[len(c) // 2:, 3] = 0.0
        ds.append(Hinh(v.v, v.i, v.n, c))
    return ghep(ds)


def cang():
    lo = Lo()
    rng = np.random.default_rng(12)
    p = _dia("cang")
    # Nhà dân màu tươi quanh quảng trường.
    tuong = ["#f6c28b", "#ea8f7a", "#f6e3a8", "#8ccbd4", "#f4a9b8", "#b9d98b", "#e8d5c0", "#ffcf70"]
    mai = ["#b8482e", "#a23c2b", "#c75a2e", "#7a4f37", "#3f6e8c", "#b8482e", "#a23c2b", "#c75a2e"]
    cho = [(-6.5, -6.0, 2.4), (-2.8, -7.8, 2.8), (1.4, -8.4, 3.1), (-7.8, -1.2, 1.7), (-8.3, 3.5, 1.5),
            (-5.8, 7.2, .6), (-1.6, 8.6, .1), (2.8, 8.1, -.2)]
    for k, (dx, dz, g) in enumerate(cho):
        cao = rng.uniform(2.4, 3.6)
        nha(lo, rng, p + (dx, 0, dz), g, mau(tuong[k]), mau(mai[k]), rng.uniform(2.8, 3.5), rng.uniform(3.2, 4.2), cao)
    # Đài phun nước giữa quảng trường.
    dn = bien_doi(p)
    lo.them("da", tien([(2.1, 0), (2.2, .4), (2.05, .55), (1.75, .5), (0, .35)], 32).doi_mau(DA_SANG), dn)
    lo.them("nuoc", _dia_nuoc(1.8, .47), dn)
    lo.them("da", tien([(.45, .35), (.22, 1.1), (.5, 1.45), (.75, 1.6), (.2, 1.7), (.12, 2.3), (.2, 2.4), (0, 2.5)], 20).doi_mau(DA_SANG), dn)
    # Quầy chợ mái sọc.
    for k, (dx, dz, c) in enumerate(((-3.2, -3.0, "#d9412f"), (3.0, -4.2, "#2f8fd9"), (-3.8, 3.4, "#f2b632"))):
        _quay_cho(lo, rng, p + (dx, 0, dz), rng.uniform(0, TAU), mau(c))
    _cau_tau(lo, rng, p)
    for k in range(9):
        a = k / 9 * TAU
        den_duong(lo, rng, p + (np.sin(a) * 5.8, 0, np.cos(a) * 5.8))
    return lo


def _dia_nuoc(r, y):
    d = nap(r, y, 32)
    return Hinh(d.v, d.i, d.n, np.zeros((len(d.v), 4)) + [0, 0, 0, 1], np.column_stack([d.v[:, 0], d.v[:, 2]]))


def _quay_cho(lo, rng, p, goc, mau_mai):
    m = bien_doi(p, goc)
    lo.them("mau", hop(2.0, .85, 1.0, .04).doi_mau(mau("#a87747")), m @ bien_doi((0, .43, 0)))
    for x in (-1.0, 1.0):
        for z in (-.5, .5):
            lo.them("mau", hop(.09, 2.2, .09).doi_mau(GO_TOI), m @ bien_doi((x, 1.1, z)))
    for k in range(8):
        x = -1.2 + k * .343
        c = mau_mai if k % 2 else TRANG
        lo.them("mau", hop(.343, .05, 1.65).doi_mau(c), m @ bien_doi((x + .17, 2.28, 0), xoay_x=.14))
    for k in range(6):
        c = mau(["#ff6f61", "#ffd23c", "#7ed957", "#ff9f43", "#6fc3ff", "#ff8ad4"][k])
        lo.them("mau", cuc(rng, 1, .05).doi_mau(c), m @ bien_doi((-.75 + k * .3, .98, rng.uniform(-.2, .2)), ty_le=.12))


def _cau_tau(lo, rng, p):
    """Cầu tàu gỗ từ bờ cảng ra biển, phía +x."""
    dau = p + (8.0, 0.0, 1.0)
    cuoi_x = 24.0
    for k in range(int(cuoi_x / .36)):
        x = k * .36
        y = 3.0 - .05 - min(x, 5.0) * .32
        q = dau + (x, 0, 0)
        lo.them("mau", hop(.33, .09, 3.0 + rng.uniform(-.1, .1)).doi_mau(GO * rng.uniform(.82, 1.15) * np.array([1, 1, 1, 0]) + [0, 0, 0, 1]),
                bien_doi((q[0], y, q[2]), rng.uniform(-.01, .01)))
    for k in range(0, int(cuoi_x / 2.4) + 1):
        x = k * 2.4
        y = 3.0 - min(x, 5.0) * .32
        for z in (-1.45, 1.45):
            q = dau + (x, 0, z)
            lo.them("mau", ong([(q[0], MUC_NUOC - 3, q[2]), (q[0], y + .75, q[2])], .15, 8).doi_mau(GO_TOI))
            lo.them("mau", tien([(.17, y + .7), (.1, y + .82), (0, y + .85)], 8).doi_mau(GO))
            lo.theo_vl["mau"][-1] = lo.theo_vl["mau"][-1].duoi(bien_doi((q[0], 0, q[2])))
    # Thùng, kiện hàng, cẩu gỗ.
    for k in range(7):
        q = dau + (rng.uniform(1.2, 20), 0, rng.choice([-1.0, 1.0]) * rng.uniform(.6, 1.05))
        y = 3.0 - min(q[0] - dau[0], 5.0) * .32 + .03
        if k % 2:
            _thung(lo, rng, np.array([q[0], y, q[2]]))
        else:
            _thung_go(lo, rng, np.array([q[0], y, q[2]]))
    c = dau + (14.0, 3.0 - 1.6 - 3.0, -1.1)
    c = np.array([c[0], 1.45, c[2]])
    lo.them("mau", ong([c, c + (0, 5.0, 0)], .17, 8).doi_mau(GO_TOI))
    lo.them("mau", ong([c + (-.2, 4.5, 0), c + (3.4, 5.6, 0)], .11, 8).doi_mau(GO))
    lo.them("kim", ong([c + (3.4, 5.6, 0), c + (3.4, 3.0, 0)], .025, 5).doi_mau(mau("#4a463f")))
    _thung_go(lo, rng, c + (3.4, 2.0, 0), .95)


def tau_buom():
    """Thuyền buồm lớn, tâm ở mặt nước. Mũi hướng +z."""
    lo = Lo()
    rng = np.random.default_rng(13)
    s = np.linspace(-1, 1, 25)
    tiet = []
    for t in s:
        z = t * 8.5
        rong = 2.5 * (1 - abs(t) ** 2.6) ** .7 + .02
        day = -1.5 + 1.0 * abs(t) ** 2
        mep = 1.6 + 1.9 * abs(t) ** 2.4 + (.5 if t < -.55 else 0)
        a = np.linspace(-np.pi * .5, np.pi * .5, 11)
        x = np.sin(a) * rong
        y = day + (np.cos(a) ** .0) * 0 + (mep - day) * (1 - np.cos(a) ** 1.5)
        tiet.append(np.stack([x, y, np.full_like(x, z)], 1))
    tiet = np.array(tiet)
    n_a = tiet.shape[1]
    tam = []
    for r in range(len(tiet) - 1):
        for k in range(n_a - 1):
            p = r * n_a + k
            tam += [[p, p + 1, p + n_a], [p + 1, p + n_a + 1, p + n_a]]
    t_mau = np.array([mau("#7b4322") if (r % 3) else mau("#5e331a") for r in range(len(tiet)) for _ in range(n_a)])
    y_ = tiet[..., 1].ravel()
    t_mau[y_ > 1.5] = mau("#d9b45a")
    t_mau[y_ < -.05] = mau("#3a2a22")
    than = Hinh(tiet.reshape(-1, 3), tam, c=t_mau)
    # Tam giác trên đang quay vào trong với x+: lấy theo pháp tuyến hướng ra.
    if np.mean(np.sum(than.n * (than.v - than.v.mean(0)), 1)) < 0:
        than = Hinh(than.v, than.i[:, [0, 2, 1]], c=than.c)
    lo.them("mau", than)
    for t in (.72, .1, -.55):
        z = t * 8.5
        boong = hop(4.4 * (1 - abs(t) ** 2.6) ** .7, .15, 2.4 if t != .1 else 8.2)
        lo.them("mau", boong.doi_mau(mau("#a87747")), bien_doi((0, 1.7 + (.45 if t < -.4 else 0) + (.1 if t > .6 else 0), z)))
    cuoi = bien_doi((0, 2.6, -6.2))
    lo.them("mau", hop(3.8, 1.5, 3.2, .1).doi_mau(mau("#6c3a1f")), cuoi)
    for x in (-1.1, 0, 1.1):
        lo.them("phat_sang", hop(.5, .55, .08).doi_mau(mau("#ffd27a")), cuoi @ bien_doi((x, .1, -1.62)))
    for z, cao, rong in ((4.3, 13.0, 4.2), (-1.0, 16.0, 5.3), (-5.2, 11.0, 3.3)):
        lo.them("mau", ong([(0, 1.5, z), (0, cao, z)], np.linspace(.2, .07, 2), 10).doi_mau(GO_TOI))
        for y0, ti in ((cao * .47, 1.0), (cao * .8, .7)):
            lo.them("mau", ong([(-rong * ti * .55, y0 + 1.8, z), (rong * ti * .55, y0 + 1.8, z)], .06, 6).doi_mau(GO))
            lo.them("mau", _buom(rong * ti, 3.6 * ti), bien_doi((0, y0 - 1.2 * ti, z + .14)))
    lo.them("mau", ong([(0, 2.3, 8.5), (0, 4.3, 12.5)], .09, 6).doi_mau(GO_TOI))
    lo.them("mau", _co_duoi_nheo(), bien_doi((0, 16.0, -1.0)))
    for z, y in ((8.5, 2.3),):
        for x in (-.8, .8):
            lo.them("kim", ong([(0, 4.2, 12.3), (x * 2.2, 2.0, 6)], .018, 4).doi_mau(mau("#6a5f4d")))
    for x in (-1, 1):
        for k in range(5):
            lo.them("kim", ong([(x * 2.05, 1.05, -1.0 + k * 1.3), (x * 2.65, 1.1, -1.0 + k * 1.3)], .09, 8).doi_mau(mau("#2c2926")))
    lo.them("kim", ong([(0, 1.6, -1), (2.6, 8.2, -1)], .017, 4).doi_mau(mau("#6a5f4d")))
    lo.them("kim", ong([(0, 1.6, -1), (-2.6, 8.2, -1)], .017, 4).doi_mau(mau("#6a5f4d")))
    return lo


def _buom(rong, cao):
    """Buồm phồng, kẻ sọc."""
    nu, nv = 13, 7
    u, v = np.meshgrid(np.linspace(-1, 1, nu), np.linspace(0, 1, nv))
    b = (1 - u ** 2) * np.sin(v * np.pi)
    x = u * rong * .5 * (1 - .12 * (1 - v))
    p = np.stack([x, v * cao, b * .75], 2)
    p[..., 1] -= (1 - np.abs(u)) * 0
    tam = []
    for r in range(nv - 1):
        for k in range(nu - 1):
            a = r * nu + k
            tam += [[a, a + 1, a + nu], [a + 1, a + nu + 1, a + nu]]
    c = np.where((np.floor((u + 1) * 3.5).astype(int) % 2 == 0)[..., None], TRANG[None, None], DO[None, None])
    h = Hinh(p.reshape(-1, 3), tam, c=c.reshape(-1, 4))
    hai_mat = Hinh(h.v, h.i[:, [0, 2, 1]], -h.n, h.c)
    return ghep([h, hai_mat])


def _co_duoi_nheo():
    a = np.array([(0, 0, 0), (0, -.8, 0), (2.2, -.4, 0)], float)
    h = Hinh(a, [[0, 2, 1]], c=np.tile(DO, (3, 1)))
    return ghep([h, Hinh(a, [[0, 1, 2]], c=np.tile(DO, (3, 1)))])


def hoi_cho():
    lo = Lo()
    rng = np.random.default_rng(14)
    p = _dia("hoi_cho")
    _leu_lon(lo, rng, p + (7.0, 0, -1.0), 5.2, 6.8, DO, TRANG)
    _leu_lon(lo, rng, p + (5.5, 0, 7.4), 3.0, 4.2, mau("#2f6fd9"), VANG)
    _leu_lon(lo, rng, p + (11.8, 0, 4.0), 2.6, 3.8, mau("#7a3fd1"), TRANG)
    # Giá vòng đu quay: gốc đặt tại trục quay.
    tam = _tam_vong_quay()
    cao_tru = tam[1] - p[1]
    for z in (-1.5, 1.5):
        for phia in (-1, 1):
            lo.them("kim", ong([tam + (0, 0, z), (tam[0] + phia * 4.3, p[1], tam[2] + z * 1.3)], .18, 10).doi_mau(mau("#c2452d")))
    lo.them("kim", ong([tam + (0, 0, -2.1), tam + (0, 0, 2.1)], .22, 12).doi_mau(mau("#f2d16b")))
    lo.them("da", hop(10.5, .4, 5.2, .1).doi_mau(DA_XAM), bien_doi(p + (tam[0] - p[0], .08, tam[2] - p[2])))
    _ = cao_tru
    # Cổng hội chợ.
    cong = p + (-.5, 0, -8.8)
    for x in (-3.0, 3.0):
        lo.them("mau", tien([(.5, 0), (.42, .4), (.36, 5.2), (.46, 5.5), (0, 5.8)], 16,
                mau_hang=[DO, TRANG, DO, VANG, VANG]), bien_doi(cong + (x, 0, 0)))
        lo.them("kim", cuc(rng, 2, 0).doi_mau(VANG), bien_doi(cong + (x, 6.0, 0), ty_le=.34))
    vom = nan_duong([(-3, 5.2, 0), (-1.6, 6.3, 0), (0, 6.7, 0), (1.6, 6.3, 0), (3, 5.2, 0)], 6)
    lo.them("mau", ong(vom + cong, .2, 10).doi_mau(DO))
    for k in range(13):
        q = vom[k * 2 % len(vom)] + cong
        lo.them("phat_sang", cuc(rng, 1, 0).doi_mau(mau("#ffe7a0")), bien_doi(q - (0, .22, .05), ty_le=.13))
    # Dây cờ nối các cột.
    cot = [p + (-8, 0, -6), p + (-8.5, 0, 2), p + (-6, 0, 8), p + (1, 0, 10), p + (-1, 0, -6), p + (3.0, 0, -7.5)]
    for q in cot:
        lo.them("mau", tien([(.14, 0), (.1, 4.6), (.16, 4.7), (0, 4.8)], 8).doi_mau(mau("#7b4e2b")), bien_doi(q))
    for a, b in zip(cot, cot[1:]):
        _day_co(lo, rng, a + (0, 4.5, 0), b + (0, 4.5, 0))
    for k, q in enumerate([p + (-5, 0, -2), p + (-4.2, 0, 5.0), p + (2, 0, 4.0), p + (1.8, 0, -3.5)]):
        _quay_cho(lo, rng, q, rng.uniform(0, TAU), mau(["#ff6f61", "#2fa8d9", "#f2b632", "#7a3fd1"][k]))
    for q in (p + (-9, 0, -2), p + (-7, 0, 5.5), p + (1, 0, 7.5), p + (2.5, 0, -6)):
        den_duong(lo, rng, q, "#ffc46b")
    return lo


def _tam_vong_quay():
    p = _dia("hoi_cho")
    return p + (-6.0, 8.3, 7.0) * np.array([1, 1, 1])


def _leu_lon(lo, rng, p, r, cao, m1, m2):
    n = 48
    so_soc = 12
    sọc = lambda a: np.where((np.floor(a / TAU * so_soc).astype(int) % 2 == 0)[:, None], m1[None], m2[None])
    than = tien([(r, 0), (r, cao * .35)], n, mau_goc=sọc)
    mai = tien([(r * 1.1, cao * .35), (r * .55, cao * .63), (r * .25, cao * .82), (.1, cao), (0, cao + .1)], n, mau_goc=sọc)
    lo.them("mau", ghep([than, mai]), bien_doi(p))
    lo.them("mau", nap(r * 1.1, cao * .35, n, len_tren=False).doi_mau(m2), bien_doi(p))
    for k in range(so_soc * 2):
        a = k / (so_soc * 2) * TAU
        lo.them("mau", cuc(rng, 1, 0).doi_mau(VANG), bien_doi(p + (np.sin(a) * r * 1.1, cao * .33, np.cos(a) * r * 1.1), ty_le=(.17, .24, .17)))
    lo.them("kim", ong([p + (0, cao, 0), p + (0, cao + 1.3, 0)], .05, 6).doi_mau(mau("#4a463f")))
    lo.them("mau", _co_duoi_nheo(), bien_doi(p + (0, cao + 1.3, 0), ty_le=.6))


def _day_co(lo, rng, a, b):
    mang = ["#ff6f61", "#ffd23c", "#7ed957", "#6fc3ff", "#ff8ad4"]
    so = int(np.linalg.norm(b - a) / .55)
    q = [a + (b - a) * (k / so) + (0, -np.sin(k / so * np.pi) * .55, 0) for k in range(so + 1)]
    lo.them("kim", ong(q, .018, 4).doi_mau(mau("#4a463f")))
    goc = np.arctan2((b - a)[0], (b - a)[2])
    for k, c in enumerate(q[:-1]):
        tg = np.array([(-.13, 0, 0), (.13, 0, 0), (0, -.34, 0)], float)
        h = Hinh(tg, [[0, 2, 1]], c=np.tile(mau(mang[k % 5]), (3, 1)))
        h2 = Hinh(tg, [[0, 1, 2]], c=h.c)
        lo.them("mau", ghep([h, h2]), bien_doi(c, goc + np.pi / 2))


def vong_quay():
    """Bánh xe đu quay ở gốc; trục quay là Y để node xoay quanh Y sau khi dựng nghiêng."""
    lo = Lo()
    rng = np.random.default_rng(15)
    r = 6.6
    so_cabin = 10
    a = np.linspace(0, TAU, 49)
    for y in (-1.0, 1.0):
        vong = np.column_stack([np.sin(a) * r, np.full_like(a, y), np.cos(a) * r])
        lo.them("kim", ong(vong, .11, 8).doi_mau(mau("#f6efe0")))
        vong2 = np.column_stack([np.sin(a) * r * .55, np.full_like(a, y), np.cos(a) * r * .55])
        lo.them("kim", ong(vong2, .06, 6).doi_mau(mau("#f2b632")))
    bang_cabin = ["#ff6f61", "#ffd23c", "#7ed957", "#6fc3ff", "#ff8ad4"]
    for k in range(so_cabin * 2):
        g = k / (so_cabin * 2) * TAU
        d = np.array([np.sin(g), 0, np.cos(g)])
        for y in (-1.0, 1.0):
            lo.them("kim", ong([(0, y * .6, 0), d * r + (0, y, 0)], .05, 6).doi_mau(mau("#d9412f")))
        if k % 2 == 0:
            lo.them("kim", ong([d * r + (0, -1, 0), d * r + (0, 1, 0)], .05, 6).doi_mau(mau("#f6efe0")))
            c = mau(bang_cabin[k // 2 % 5])
            lo.them("mau", cuc(rng, 2, 0, det=(.58, .95, .58)).doi_mau(c), bien_doi(d * (r + .15)))
            lo.them("phat_sang", cuc(rng, 1, 0).doi_mau(mau("#ffe7a0")), bien_doi(d * r + (0, 1.14, 0), ty_le=.13))
            lo.them("phat_sang", cuc(rng, 1, 0).doi_mau(mau("#ffe7a0")), bien_doi(d * r + (0, -1.14, 0), ty_le=.13))
    return lo


def den_thap():
    """Đền bậc thang cổ, phía tây."""
    lo = Lo()
    rng = np.random.default_rng(16)
    p = _dia("den_thap")
    tang = [(17.0, 1.6), (14.0, 1.6), (11.0, 1.6), (8.0, 1.6), (5.4, 1.5)]
    y = 0.0
    for k, (c, h) in enumerate(tang):
        m = bien_doi(p + (0, y + h * .5, 0))
        lo.them("da", hop(c, h, c, .18).doi_mau(mau("#c8b48f") * np.array([.82 + k * .04] * 3 + [1])), m)
        # Hoa văn: đá khắc nhô ở mỗi mặt.
        for phia in range(4):
            g = phia * np.pi / 2
            for s in np.linspace(-.42, .42, max(int(c / 1.6), 3)):
                lo.them("da", hop(.75, h * .55, .22, .05).doi_mau(mau("#a4906c")),
                        bien_doi(p + (0, y + h * .5, 0), g) @ bien_doi((s * c, 0, c * .5 + .03)))
        y += h
    # Cầu thang phía đông nhìn về bàn.
    for k in range(32):
        x = 8.6 - k * .185
        lo.them("da", hop(.3, .34, 3.0, .03).doi_mau(mau("#d8c9a6") * np.array([.92 + (k % 2) * .08] * 3 + [1])),
                bien_doi(p + (x, k * .25 + .16, 0)))
    for z in (-1.7, 1.7):
        lo.them("da", ong([p + (8.8, 0.2, z), p + (2.8, 8.2, z)], .34, 8).doi_mau(mau("#a4906c")))
        lo.them("da", cuc(rng, 2, .08).doi_mau(mau("#c8b48f")), bien_doi(p + (9.0, .5, z), ty_le=.62))
    # Đình đỉnh.
    dinh = p + (0, y, 0)
    for k in range(8):
        g = k / 8 * TAU + np.pi / 8
        q = dinh + (np.sin(g) * 2.1, 0, np.cos(g) * 2.1)
        lo.them("da", tien([(.42, 0), (.34, .2), (.26, .4), (.22, 2.6), (.34, 2.8), (.44, 3.0)], 14).doi_mau(mau("#e2d6ba")), bien_doi(q))
    lo.them("da", tien([(2.85, 3.0), (2.85, 3.4), (2.2, 3.7), (1.3, 4.5), (.3, 5.2), (0, 5.3)], 32).doi_mau(mau("#c4a65c")), bien_doi(dinh))
    lo.them("da", nap(2.85, 3.0, 32, len_tren=False).doi_mau(mau("#d8ccb4")), bien_doi(dinh))
    # Tượng canh, chậu lửa.
    for x, z in ((10.5, -5.0), (10.5, 5.0)):
        q = p + (x, 0, z)
        lo.them("da", hop(1.3, .8, 1.3, .08).doi_mau(mau("#a4906c")), bien_doi(q + (0, .4, 0)))
        lo.them("da", cuc(rng, 2, .05, det=(.65, 1.2, .55)).doi_mau(mau("#8b9e7f")), bien_doi(q + (0, 1.9, 0)))
        lo.them("da", cuc(rng, 2, .05, det=(.5, .55, .55)).doi_mau(mau("#8b9e7f")), bien_doi(q + (0, 3.4, 0)))
        lo.them("kim", tien([(.42, 0), (.2, .55), (.2, .9), (.5, 1.15), (.56, 1.3), (.38, 1.2), (0, 1.15)], 16).doi_mau(mau("#6b5b3a")), bien_doi(q + (0, 0, -2.2 if z < 0 else 2.2)))
    # Cột đổ quanh đền.
    for k in range(7):
        g = rng.uniform(0, TAU)
        q = p + (np.sin(g) * rng.uniform(10, 11.5), .35, np.cos(g) * rng.uniform(10, 11.5))
        if q[0] - p[0] > 6 and abs(q[2] - p[2]) < 3:
            continue
        m = bien_doi(q, rng.uniform(0, TAU), 1.0, xoay_x=rng.uniform(1.2, 1.57))
        lo.them("da", tien([(.42, 0), (.38, 2.8 * rng.uniform(.5, 1)), (.0, 3.0)], 12).doi_mau(mau("#b8ab8e")), m)
        lo.them("da", nap(.42, 0, 12, len_tren=False).doi_mau(mau("#b8ab8e")), m)
    return lo


def tinh_the():
    """Pha lê nổi trên đỉnh đền."""
    rng = np.random.default_rng(17)
    ds = []
    for a, b, c in (((0, 0, 0), 1.0, 0.0), ((.42, -.2, .18), .5, .25), ((-.38, -.18, -.2), .55, -.3)):
        h = tien([(0, -1.1), (.46, -.2), (.36, .75), (0, 1.25)], 6).duoi(bien_doi(a, c, b))
        n = h.n
        ds.append(h.doi_mau(mau("#5cf2ff")))
    return ghep(ds)


def vinh_cuop():
    """Vịnh cướp biển: tảng đá đầu lâu, xác tàu, rương vàng."""
    lo = Lo()
    rng = np.random.default_rng(18)
    p = _dia("vinh_cuop")
    # Đá đầu lâu giữa nước.
    dl = np.array([-20.0, MUC_NUOC - 1.2, -49.0])
    so = cuc(rng, 4, .05, 2.4, (6.6, 6.6, 6.2), 3)
    ham = cuc(rng, 3, .06, 2.0, (4.2, 2.6, 3.8), 3)
    mat = np.array([(-2.4, 4.8, 5.0), (2.4, 4.8, 5.0)])
    v = so.v.copy() + np.array([0, 7.6, 0])
    # Khoét hốc mắt và mũi: đẩy đỉnh vào trong, đồng thời tô tối.
    c = np.tile(mau("#c7bfae"), (len(v), 1))
    for tam, r in [(mat[0] + (0, 2.8, 0), 2.1), (mat[1] + (0, 2.8, 0), 2.1), ((0, 5.8, 6.1), 1.0)]:
        d = np.linalg.norm(v - np.array(tam), axis=1)
        w = np.clip(1 - d / r, 0, 1) ** .6
        v[:, 2] -= w * 2.3
        c[:, :3] *= (1 - w[:, None] * .92)
    lo.them("da", Hinh(v, so.i, c=c), bien_doi(dl, -.35))
    lo.them("da", ham.doi_mau(mau("#a89f8d")), bien_doi(dl, -.35) @ bien_doi((0, 1.6, 2.8)))
    for k in range(6):
        x = -2.0 + k * .8
        lo.them("da", hop(.56, 1.0, .5, .1).doi_mau(mau("#eee6d2")), bien_doi(dl, -.35) @ bien_doi((x, 3.5, 5.9 - abs(x) * .3)))
    # Xác tàu đắm nghiêng.
    xac = tau_buom()
    gop = xac.gop()
    m_xac = bien_doi((2.0, MUC_NUOC - 2.2, -52.0), 2.4, 1.0, xoay_x=-.22, xoay_z=.42)
    h = gop["mau"]
    giu = h.v[h.i].max(axis=1)[:, 1] < 9.0
    lo.them("mau", Hinh(h.v, h.i[giu], h.n, h.c * np.array([.55, .52, .5, 1.0])), m_xac)
    # Bến cát với rương vàng.
    ruong = p + (2.0, 0.05, -2.0)
    m = bien_doi(ruong, .5)
    lo.them("mau", hop(1.7, .9, 1.1, .08).doi_mau(mau("#7b4322")), m @ bien_doi((0, .45, 0)))
    lo.them("mau", cuc(rng, 2, 0, det=(.86, .5, .56)).doi_mau(mau("#8a4f26")), m @ bien_doi((0, 1.1, -.25), xoay_x=-.5))
    for x in (-.65, 0, .65):
        lo.them("kim", hop(.14, .92, 1.14).doi_mau(VANG), m @ bien_doi((x, .46, 0)))
    dong_xu = tien([(.13, 0), (.13, .03), (0, .03)], 10).doi_mau(mau("#ffcf33"))
    for k in range(70):
        a, r = rng.uniform(0, TAU), rng.uniform(.5, 2.4) * rng.random() ** .5
        q = ruong + (np.sin(a) * r, .06 + max(0, .7 - r * .32) * rng.random(), np.cos(a) * r + .6)
        lo.them("kim", dong_xu, bien_doi(q, rng.uniform(0, TAU), 1.0, xoay_x=rng.uniform(-.6, .6), xoay_z=rng.uniform(-.6, .6)))
    for k in range(5):
        _thung(lo, rng, p + (rng.uniform(-5, 5), 0, rng.uniform(-5, 3)))
    # Bia đuốc quanh vịnh.
    for dx, dz in ((-5.5, 2.5), (5.5, 2.5), (-3.5, -5.5), (5.0, -5.0)):
        den_duong(lo, rng, p + (dx, 0, dz), "#ff9a4d")
    return lo


def coi_xay(ten):
    lo = Lo()
    rng = np.random.default_rng(hash(ten) & 0xFFFF)
    p = _dia(ten)
    s = np.linspace(0, 1, 13)
    lo.them("mau", tien(np.column_stack([3.1 - s * 1.3, s * 9.0]), 28, mau_hang=np.tile(mau("#f0e6cf"), (13, 1))).toi_day(.8), bien_doi(p))
    lo.them("da", tien([(3.3, 0), (3.28, 1.0), (3.1, 1.05)], 28).doi_mau(DA_XAM), bien_doi(p))
    lo.them("mau", tien([(1.95, 9.0), (2.0, 9.15), (1.5, 10.2), (.8, 11.1), (0, 11.5)], 28).doi_mau(mau("#a83a2a")), bien_doi(p))
    lo.them("mau", nap(1.95, 9.0, 28, len_tren=False).doi_mau(mau("#7d2a1f")), bien_doi(p))
    lo.them("mau", hop(1.1, 1.8, .2, .04).doi_mau(GO), bien_doi(p + (0, 1.1, 3.0)))
    for y in (3.8, 6.3):
        lo.them("phat_sang", hop(.6, .8, .12).doi_mau(mau("#ffd27a")), bien_doi(p + (0, y, 3.05 - y * .13)))
        lo.them("mau", hop(.76, .96, .08).doi_mau(GO_TOI), bien_doi(p + (0, y, 3.0 - y * .13)))
    lo.them("kim", ong([p + (0, 9.3, 1.2), p + (0, 9.3, 2.6)], .2, 10).doi_mau(mau("#4a463f")))
    return lo


def canh_quat():
    """Bốn cánh quạt gió ở gốc; trục quay Y (node dựng nghiêng cho trục ra phía trước)."""
    lo = Lo()
    for k in range(4):
        g = k * np.pi / 2
        m = bien_doi((0, 0, 0), g)
        lo.them("mau", hop(.2, .14, 6.6).doi_mau(mau("#6a4a2e")), m @ bien_doi((0, 0, 3.3)))
        lo.them("mau", hop(1.5, .05, 5.0).doi_mau(mau("#f6efe0")), m @ bien_doi((.82, .03, 3.9)))
        for t in range(6):
            lo.them("mau", hop(1.55, .1, .08).doi_mau(mau("#6a4a2e")), m @ bien_doi((.82, 0, 1.6 + t * .92)))
    lo.them("kim", tien([(.42, -.4), (.42, .3), (0, .46)], 14).doi_mau(mau("#4a463f")))
    return lo


def lang_nam():
    lo = Lo()
    rng = np.random.default_rng(19)
    p = _dia("lang_nam")
    nha(lo, rng, p + (-2.0, 0, -1.0), .5, mau("#f6c28b"), mau("#b8482e"))
    nha(lo, rng, p + (2.6, 0, 1.2), -.6, mau("#8ccbd4"), mau("#3f6e8c"), 3.0, 3.6, 2.8)
    _quay_cho(lo, rng, p + (.5, 0, -3.5), .2, mau("#ff8a3c"))
    for dx, dz in ((-4.2, 2.4), (4.6, -2.2)):
        den_duong(lo, rng, p + (dx, 0, dz))
    return lo


def den_ven_duong(dh):
    """Đèn đường đều dọc vòng ngoài, đặt phía ngoài đường, tránh sông."""
    lo = Lo()
    rng = np.random.default_rng(20)
    d = dh.duong[0]
    for k in range(0, len(d), 26):
        p = d[k]
        q = d[(k + 1) % len(d)]
        f = (q - p) / max(np.linalg.norm(q - p), 1e-6)
        ngoai = np.array([f[1], -f[0]])
        if ngoai @ p < 0:
            ngoai = -ngoai
        c = p + ngoai * 2.1
        if dh.cay_song.query(c)[0] > 2.2 and dh.cay_o.query(c)[0] > 1.9:
            den_duong(lo, rng, np.array([c[0], float(dh.cao(c[0], c[1])) - .03, c[1]]))
    return lo


def may(rng):
    """Một cụm mây mịn."""
    ds = []
    so = rng.integers(6, 11)
    for k in range(so):
        r = rng.uniform(4.0, 9.0)
        tam = (rng.uniform(-16, 16), rng.uniform(-1.0, 3.0), rng.uniform(-8, 8))
        h = cuc(rng, 3, .1, 1.9, (r * 1.3, r * .65, r), 3).duoi(bien_doi(tam))
        t = np.clip((h.v[:, 1] + 3.0) / 10.0, 0, 1)[:, None]
        c = mau("#b8cde0") * (1 - t) + mau("#ffffff") * t
        ds.append(Hinh(h.v, h.i, h.n, c))
    return ghep(ds)


def chim(rng):
    """Hải âu: thân + hai cánh gập."""
    than = cuc(rng, 2, 0, det=(.16, .16, .5)).doi_mau(mau("#fafafa"))
    canh = []
    for phia in (-1, 1):
        v = np.array([(0, 0, .2), (phia * .9, .2, .1), (phia * 1.6, .05, -.1), (phia * .9, .2, -.28), (0, 0, -.2)], float)
        i = [[0, 1, 4], [1, 3, 4], [1, 2, 3]]
        if phia < 0:
            i = [[a, c, b] for a, b, c in i]
        h = Hinh(v, i, c=np.tile(mau("#f0f0f0"), (5, 1)))
        canh += [h, Hinh(v, [[a, c, b] for a, b, c in i], c=h.c)]
    return ghep([than, *canh, cuc(rng, 1, 0).duoi(bien_doi((0, 0, .55), ty_le=(.06, .05, .13))).doi_mau(mau("#f2a13a"))])
