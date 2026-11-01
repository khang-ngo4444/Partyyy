"""Cây dừa, cây tán, bụi, dương xỉ, cỏ, hoa, đá. Màu đỉnh A = độ đung đưa theo gió."""
import numpy as np
from scipy.spatial import cKDTree

from dia_hinh import DIA_DIEM, MUC_NUOC, _o_khu, fbm
from hinh import Hinh, Lo, TAU, bang, bien_doi, cuc, ghep, mau, ong, tien


def _gio(h, nen=0.0, dinh=1.0):
    """Ghi độ đung đưa theo chiều cao vào kênh A."""
    y = h.v[:, 1]
    t = (y - y.min()) / max(float(np.ptp(y)), 1e-5)
    c = h.c.copy()
    c[:, 3] = nen + (dinh - nen) * t
    return Hinh(h.v, h.i, h.n, c, h.uv)


def _la_dua(rng, dai, mau_goc, mau_ngon):
    """Tàu dừa cong: sống lá gãy hình chữ V, mép răng cưa."""
    n = 13
    s = np.linspace(0, 1, n * 2 + 1)
    x = s * dai
    y = np.sin(s * 1.5) * dai * 0.32 - s ** 2.3 * dai * 0.62
    tam = np.column_stack([np.zeros_like(s), y, x])
    rang = np.where(np.arange(len(s)) % 2 == 0, 1.0, 0.62)
    rong = np.sin(np.clip(s * 1.15 + 0.08, 0, 1) * np.pi) ** 0.7 * dai * 0.17 * rang
    trai = tam + np.column_stack([-rong, -rong * 0.42, np.zeros_like(s)])
    phai = tam + np.column_stack([rong, -rong * 0.42, np.zeros_like(s)])
    v = np.concatenate([trai, tam, phai])
    m = len(s)
    j = np.arange(m - 1)
    # Hai mặt nghiêng của lá, nhìn từ trên xuống.
    ti = np.concatenate([np.stack([j, j + 1, j + m], 1), np.stack([j + 1, j + m + 1, j + m], 1),
            np.stack([j + m, j + m + 1, j + 2 * m], 1), np.stack([j + m + 1, j + 2 * m + 1, j + 2 * m], 1)])
    t = np.tile(s, 3)[:, None]
    c = np.asarray(mau_goc) * (1 - t) + np.asarray(mau_ngon) * t
    c[:, 3] = t[:, 0] * 0.8 + 0.2
    c[m:2 * m, :3] *= 0.74
    return Hinh(v, ti, c=c)


def cay_dua(rng):
    """Trả (thân, lá). Gốc ở y = 0."""
    cao = rng.uniform(7.0, 10.5)
    nghieng = rng.uniform(0.9, 2.2)
    s = np.linspace(0, 1, 15)
    duong = np.column_stack([s ** 2 * nghieng, s * cao, np.zeros_like(s)])
    vong = 0.3 - 0.13 * s + 0.018 * np.sin(s * 70)
    vong[0] = 0.52
    nau = mau("#7d5b3a")
    sang = mau("#a98a62")
    than = [ong(duong, vong, 9, nau, sang)]
    dinh = duong[-1]
    ten = rng.integers(0, 3)
    goc_la, ngon_la = mau(["#2f8a35", "#2c7f3d", "#3b9433"][ten]), mau(["#a7d13c", "#8ed04a", "#c0d843"][ten])
    la = []
    so = rng.integers(10, 14)
    for k in range(so):
        a = k / so * TAU + rng.uniform(-0.15, 0.15)
        dai = rng.uniform(3.6, 5.0)
        h = _la_dua(rng, dai, goc_la, ngon_la)
        la.append(h.duoi(bien_doi(dinh, a, 1.0, xoay_x=rng.uniform(-0.22, 0.2) - (k % 3) * 0.12)))
    for k in range(4):
        a = k / 4 * TAU + 0.5
        qua = cuc(rng, 1, 0.05).duoi(bien_doi(dinh + np.array([np.sin(a) * .28, -.3, np.cos(a) * .28]), ty_le=.22))
        than.append(qua.doi_mau(mau("#5c3a1e")))
    return ghep(than), ghep(la)


def cay_tan(rng, bang_mau):
    """Cây tán to: thân rẽ nhánh + nhiều cụm lá sần."""
    cao = rng.uniform(3.6, 5.6)
    canh, tan = [], []
    than_chinh = [(0, 0, 0), (rng.uniform(-.3, .3), cao * .45, rng.uniform(-.3, .3)), (0, cao * 0.8, 0)]
    canh.append(ong(np.array(than_chinh), [0.62, 0.36, 0.2], 9, mau("#59402a"), mau("#7a5a3c")))
    so = rng.integers(6, 9)
    m_toi, m_sang = bang_mau
    for k in range(so):
        a = k / so * TAU + rng.uniform(-.3, .3)
        r = rng.uniform(1.0, 2.0) if k else 0.0
        y = cao * rng.uniform(0.78, 1.08) + (1.3 if k == 0 else 0.0)
        tam = np.array([np.sin(a) * r, y, np.cos(a) * r])
        if k:
            canh.append(ong(np.array([(0, cao * .55, 0), tam * .55 + [0, cao * .25, 0], tam]),
                    [0.22, 0.14, 0.08], 6, mau("#59402a"), mau("#6a4c32")))
        rr = rng.uniform(1.0, 1.6) * (1.2 if k == 0 else 1.0)
        khoi = cuc(rng, 2, 0.24, 3.6, (rr, rr * .82, rr), 3).duoi(bien_doi(tam))
        d = (khoi.v[:, 1] - (tam[1] - rr)) / (2 * rr)
        t = np.clip(d, 0, 1)[:, None]
        c = np.asarray(m_toi) * (1 - t) + np.asarray(m_sang) * t
        c[:, 3] = np.clip(0.35 + t[:, 0] * 0.65, 0, 1)
        tan.append(Hinh(khoi.v, khoi.i, khoi.n, c))
    return ghep(canh), ghep(tan)


def bui(rng, bang_mau, co_hoa=None):
    khoi = []
    m_toi, m_sang = bang_mau
    so = rng.integers(2, 5)
    for k in range(so):
        rr = rng.uniform(0.45, 0.9)
        tam = (rng.uniform(-.7, .7), rr * .65, rng.uniform(-.7, .7))
        h = cuc(rng, 2, 0.26, 4.2, (rr, rr * .8, rr), 3).duoi(bien_doi(tam))
        t = np.clip(h.v[:, 1] / (rr * 1.6), 0, 1)[:, None]
        c = np.asarray(m_toi) * (1 - t) + np.asarray(m_sang) * t
        c[:, 3] = t[:, 0] * 0.5
        khoi.append(Hinh(h.v, h.i, h.n, c))
    ghep_bui = ghep(khoi)
    if co_hoa is not None:
        chon = rng.choice(len(ghep_bui.v), size=14)
        them = []
        for q in ghep_bui.v[chon]:
            if q[1] > 0.25:
                them.append(cuc(rng, 0, 0.0).duoi(bien_doi(q, ty_le=rng.uniform(.06, .1))).doi_mau(co_hoa))
        if them:
            ghep_bui = ghep([ghep_bui] + them)
    return ghep_bui


def duong_xi(rng, mau_goc, mau_ngon):
    la = []
    so = rng.integers(7, 11)
    for k in range(so):
        h = _la_dua(rng, rng.uniform(.9, 1.5), mau_goc, mau_ngon)
        v = h.v.copy()
        v[:, 1] += 0.72
        la.append(Hinh(v, h.i, h.n, h.c).duoi(bien_doi((0, 0, 0), k / so * TAU + rng.uniform(-.2, .2))))
    return ghep(la)


def chum_co(rng, mau_goc, mau_ngon, so_la=7):
    """Bó lá cỏ ba đốt."""
    ds = []
    for _ in range(so_la):
        cao = rng.uniform(0.3, 0.62)
        a = rng.uniform(0, TAU)
        goc = np.array([rng.uniform(-.17, .17), 0.0, rng.uniform(-.17, .17)])
        huong = np.array([np.sin(a), 0, np.cos(a)]) * rng.uniform(.08, .26)
        s = np.linspace(0, 1, 4)
        duong = goc + np.outer(s, [0, cao, 0]) + np.outer(s ** 2, huong)
        ben = np.array([np.cos(a), 0, -np.sin(a)])
        rong = np.array([0.04, 0.034, 0.022, 0.002])
        t = s[:, None]
        c = np.asarray(mau_goc) * (1 - t) + np.asarray(mau_ngon) * t
        c[:, 3] = s
        ds.append(bang(duong, np.tile(ben, (4, 1)), rong, mau_hang=c))
    return ghep(ds)


def hoa(rng, mau_canh):
    """Hoa: cuống + sáu cánh quanh nhị vàng."""
    cao = rng.uniform(.3, .55)
    cuong = bang(np.array([(0, 0, 0), (0.02, cao * .5, 0), (0, cao, 0)]), np.tile((1.0, 0.0, 0.0), (3, 1)), .012,
            mau_hang=[(*mau("#3d8a35")[:3], 0.0), (*mau("#3d8a35")[:3], .5), (*mau("#57a33d")[:3], 1.0)])
    canh = []
    for k in range(6):
        a = k / 6 * TAU
        m = bien_doi((0, cao, 0), a, (.05, .012, .075), xoay_x=-.32)
        canh.append(cuc(rng, 0, 0.0).duoi(m @ bien_doi((0, 0, 1.0))).doi_mau((*mau_canh[:3], 1.0)))
    nhi = cuc(rng, 0, 0.0).duoi(bien_doi((0, cao + .012, 0), ty_le=.035)).doi_mau((*mau("#ffd23c")[:3], 1.0))
    return ghep([cuong, *canh, nhi])


def khoi_da(rng, chia=2):
    """Tảng đá mặt vát."""
    h = cuc(rng, chia, 0.22, 1.6, (1, .72, 1), 4)
    v = h.v.copy()
    d = rng.normal(size=(3, 3))
    d /= np.linalg.norm(d, axis=1, keepdims=True)
    for k in range(3):
        p = v @ d[k]
        ngat = rng.uniform(.45, .7)
        vuot = p > ngat
        v[vuot] -= np.outer(p[vuot] - ngat, d[k]) * 0.8
    return Hinh(v, h.i).toi_day(0.7)


# ───────────────────────────── rải cây ─────────────────────────────

BANG_TAN = [(mau("#1f6b3a"), mau("#6cc24a")), (mau("#22743f"), mau("#8bcf43")),
        (mau("#17603f"), mau("#49b267")), (mau("#7a3c1e"), mau("#f0a13a")), (mau("#7d2b4c"), mau("#f27aa8"))]


class Tho:
    """Bộ lọc vị trí: tránh đường, ô, sông, mặt bằng công trình."""

    def __init__(self, dh):
        self.dh = dh
        self.dia_diem = np.array([(v[0], v[1]) for v in DIA_DIEM.values()])
        self.bk_dia_diem = np.array([v[2] for v in DIA_DIEM.values()])

    def dat_duoc(self, x, z, cach_duong, doc_max=0.75, y_min=MUC_NUOC + 1.2, cay_cao=False):
        dh = self.dh
        y = float(dh.cao(x, z))
        if y < y_min or abs(x) > 62 or abs(z) > 62:
            return None
        if float(dh.lay_truong(dh.doc, x, z)) > doc_max:
            return None
        if float(dh.lay_truong(dh.d_duong, x, z)) < cach_duong:
            return None
        if float(dh.lay_truong(dh.d_song, x, z)) < 2.3:
            return None
        d = np.hypot(self.dia_diem[:, 0] - x, self.dia_diem[:, 1] - z)
        if np.any(d < self.bk_dia_diem):
            return None
        if cay_cao:
            # Camera bám ô ở phía +z, cao 8m: không trồng cây cao chắn giữa camera và ô.
            for lui in (3.0, 5.5):
                if dh.cay_duong.query((x, z - lui))[0] < 2.8:
                    return None
        return y


def trong_cay(dh, rng):
    """Trả {(a, b): Lo} cho cây lớn và {(a, b): Lo} cho cỏ/hoa."""
    tho = Tho(dh)
    cay, co = {}, {}
    lo = lambda bang_k, x, z: bang_k.setdefault(_o_khu(x, z), Lo())
    _trong_dua(dh, rng, tho, cay, lo)
    _trong_rung(dh, rng, tho, cay, lo)
    _trong_bui_da(dh, rng, tho, cay, lo)
    _trong_co(dh, rng, tho, co, lo)
    return cay, co


def _diem_ngau(rng, gioi=62.0):
    return rng.uniform(-gioi, gioi), rng.uniform(-gioi, gioi)


def _trong_dua(dh, rng, tho, cay, lo):
    mau_cay = [cay_dua(rng) for _ in range(6)]
    da_dat, dem = [], 0
    for _ in range(60000):
        if dem >= 100:
            break
        x, z = _diem_ngau(rng)
        y = tho.dat_duoc(x, z, 4.0, 0.7, MUC_NUOC + 0.9, cay_cao=True)
        if y is None or y > 9.0:
            continue
        ven_bien = float(dh.lay_truong(dh.t_bo, x, z)) > -0.3
        if not ven_bien and rng.random() > 0.08:
            continue
        p = np.array([x, z])
        if da_dat and np.min(np.linalg.norm(np.array(da_dat) - p, axis=1)) < 3.4:
            continue
        da_dat.append(p)
        than, la = mau_cay[rng.integers(len(mau_cay))]
        m = bien_doi((x, y - .15, z), rng.uniform(0, TAU), rng.uniform(.85, 1.2))
        l = lo(cay, x, z)
        l.them("mau", than, m)
        l.them("la", la, m)
        dem += 1


def _trong_rung(dh, rng, tho, cay, lo):
    mau_cay = [cay_tan(rng, BANG_TAN[k % 3]) for k in range(6)]
    mau_hong = [cay_tan(rng, BANG_TAN[3 + k % 2]) for k in range(2)]
    da_dat, dem = [], 0
    for _ in range(60000):
        if dem >= 70:
            break
        x, z = _diem_ngau(rng)
        y = tho.dat_duoc(x, z, 6.5, 0.62, MUC_NUOC + 4.5, cay_cao=True)
        if y is None or y > 9.0:
            continue
        if fbm(np.array(x), np.array(z), 0.055, 3, 71) < 0.47:
            continue
        p = np.array([x, z])
        if da_dat and np.min(np.linalg.norm(np.array(da_dat) - p, axis=1)) < 5.0:
            continue
        da_dat.append(p)
        bo = mau_hong if rng.random() < 0.07 else mau_cay
        than, tan = bo[rng.integers(len(bo))]
        m = bien_doi((x, y - .2, z), rng.uniform(0, TAU), rng.uniform(.75, 1.1))
        l = lo(cay, x, z)
        l.them("mau", than, m)
        l.them("la", tan, m)
        dem += 1


def _trong_bui_da(dh, rng, tho, cay, lo):
    mau_bui = [bui(rng, BANG_TAN[k % 3], mau(["#ff6f91", "#ffd23c", "#ffffff", "#c17bff"][k % 4]) if k % 2 else None)
            for k in range(8)]
    mau_xi = [duong_xi(rng, mau("#1f7a3a"), mau("#7ed957")) for _ in range(3)]
    mau_da = [khoi_da(rng) for _ in range(6)]
    for _ in range(260):
        x, z = _diem_ngau(rng)
        y = tho.dat_duoc(x, z, 2.2, 0.8, MUC_NUOC + 3.0)
        if y is not None:
            lo(cay, x, z).them("la", mau_bui[rng.integers(8)],
                    bien_doi((x, y - .05, z), rng.uniform(0, TAU), rng.uniform(.55, 1.1)))
    for _ in range(260):
        x, z = _diem_ngau(rng)
        y = tho.dat_duoc(x, z, 1.9, 0.8, MUC_NUOC + 3.0)
        if y is not None:
            lo(cay, x, z).them("la", mau_xi[rng.integers(3)],
                    bien_doi((x, y - .02, z), rng.uniform(0, TAU), rng.uniform(.75, 1.3)))
    # Đá: rải cả sườn núi và mép biển.
    for _ in range(380):
        x, z = _diem_ngau(rng)
        y = tho.dat_duoc(x, z, 2.4, 3.5, MUC_NUOC - 1.0)
        if y is None:
            continue
        r = rng.uniform(.3, 1.0) * (2.8 if float(dh.lay_truong(dh.doc, x, z)) > 0.9 else 1.0)
        m = bien_doi((x, y - r * .2, z), rng.uniform(0, TAU), (r * rng.uniform(.8, 1.3), r, r * rng.uniform(.8, 1.3)))
        lo(cay, x, z).them("da", mau_da[rng.integers(6)], m, mau("#8f8a7e"))
    _da_ven_bien(dh, rng, cay, lo, mau_da)


def _da_ven_bien(dh, rng, cay, lo, mau_da):
    """Đá lớn sát mép nước để chân vách không bị trơn."""
    dem = 0
    for _ in range(40000):
        if dem >= 160:
            break
        x, z = _diem_ngau(rng, 68.0)
        y = float(dh.cao(x, z))
        if not (MUC_NUOC - 2.5 < y < MUC_NUOC + 0.6) or float(dh.lay_truong(dh.mat_cat, x, z)) > 0.55:
            continue
        r = rng.uniform(.8, 2.4)
        m = bien_doi((x, MUC_NUOC + rng.uniform(-.8, .1), z), rng.uniform(0, TAU), (r, r * rng.uniform(.7, 1.3), r))
        lo(cay, np.clip(x, -63, 63), np.clip(z, -63, 63)).them("da", mau_da[rng.integers(6)], m, mau("#77736a"))
        dem += 1


def _trong_co(dh, rng, tho, co, lo):
    mau_co = [chum_co(rng, mau(a), mau(b)) for a, b in
            (("#2b7a2e", "#86cf3f"), ("#2f8236", "#a4d645"), ("#25702f", "#6fc24a"), ("#3a8a2a", "#c6dd4e"))]
    bang_hoa = [mau(c) for c in ("#ff5d8f", "#ffd23c", "#ffffff", "#b478ff", "#ff8a3c", "#5cc8ff")]
    mau_hoa = [hoa(rng, bang_hoa[k]) for k in range(6)]
    for _ in range(13000):
        x, z = _diem_ngau(rng, 58.0)
        gan = rng.random() < 0.6
        if gan:
            # Dồn cỏ dọc đường đi, chỗ camera nhìn gần nhất.
            nguon = dh.duong[rng.integers(2)]
            p = nguon[rng.integers(len(nguon))]
            a, r = rng.uniform(0, TAU), rng.uniform(1.55, 4.5)
            x, z = p[0] + np.sin(a) * r, p[1] + np.cos(a) * r
        y = tho.dat_duoc(x, z, 1.5, 0.6, 1.6)
        if y is None or float(dh.lay_truong(dh.mat_cat, x, z)) > 0.5:
            continue
        lo(co, x, z).them("la", mau_co[rng.integers(4)],
                bien_doi((x, y - .02, z), rng.uniform(0, TAU), rng.uniform(.8, 1.5)))
    for _ in range(2400):
        x, z = _diem_ngau(rng, 58.0)
        y = tho.dat_duoc(x, z, 1.5, 0.6, 1.6)
        if y is None or float(dh.lay_truong(dh.mat_cat, x, z)) > 0.4:
            continue
        if fbm(np.array(x), np.array(z), 0.09, 2, 88) < 0.5:
            continue
        lo(co, x, z).them("la", mau_hoa[rng.integers(6)],
                bien_doi((x, y, z), rng.uniform(0, TAU), rng.uniform(.8, 1.4)))
