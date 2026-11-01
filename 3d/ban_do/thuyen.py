"""Thuyền các loại và sinh vật nhỏ quanh đảo. Thuyền: gốc ở mặt nước, mũi hướng +z."""
import numpy as np

from hinh import Hinh, Lo, TAU, bien_doi, cuc, ghep, hop, mau, nap, ong, tien

TRANG = mau("#f6efe0")
DO = mau("#d9412f")
VANG = mau("#f2b632")
GO = mau("#8a5a33")
GO_TOI = mau("#5e3c20")
DAY_THUNG = mau("#6a5f4d")


def _luoi_khep(hang):
    """Lưới chữ nhật không khép vòng từ mảng hàng × cột × 3."""
    so_hang, so_cot = hang.shape[:2]
    tam = []
    for r in range(so_hang - 1):
        for k in range(so_cot - 1):
            p = r * so_cot + k
            tam += [[p, p + 1, p + so_cot], [p + 1, p + so_cot + 1, p + so_cot]]
    return tam


def _than_tau(dai, rong, day, mep, mau_ngoai, mau_doc, mau_vien):
    """Vỏ tàu: `dai`, `rong` là nửa dài, nửa rộng; `day`, `mep` là cao độ đáy và mạn."""
    tiet = []
    for t in np.linspace(-1, 1, 25):
        z = t * dai
        r = rong * (1 - abs(t) ** 2.6) ** .7 + .02
        a = np.linspace(-np.pi * .5, np.pi * .5, 11)
        d = day + (-day * .66) * t * t
        m = mep * (1 + 1.2 * abs(t) ** 2.4)
        y = d + (m - d) * (1 - np.cos(a) ** 1.5)
        tiet.append(np.stack([np.sin(a) * r, y, np.full_like(a, z)], 1))
    tiet = np.array(tiet)
    so_cot = tiet.shape[1]
    c = np.array([mau_ngoai if r % 3 else mau_doc for r in range(len(tiet)) for _ in range(so_cot)])
    y = tiet[..., 1].ravel()
    c[y > mep * .9] = mau_vien
    than = Hinh(tiet.reshape(-1, 3), _luoi_khep(tiet), c=c)
    if np.mean(np.sum(than.n * (than.v - than.v.mean(0)), 1)) < 0:
        than = Hinh(than.v, than.i[:, [0, 2, 1]], c=than.c)
    return than


def _buom(rong, cao, m1, m2, so_soc=7):
    """Buồm phồng kẻ sọc; A là độ phập phồng cho vật liệu vải."""
    u, v = np.meshgrid(np.linspace(-1, 1, 13), np.linspace(0, 1, 7))
    phong = (1 - u ** 2) * np.sin(v * np.pi)
    p = np.stack([u * rong * .5 * (1 - .12 * (1 - v)), v * cao, phong * .75], 2)
    soc = (np.floor((u + 1) * so_soc * .5).astype(int) % 2 == 0)[..., None]
    c = np.where(soc, m1[None, None], m2[None, None]).copy()
    c[..., 3] = .15 + phong * .85
    return Hinh(p.reshape(-1, 3), _luoi_khep(p), c=c.reshape(-1, 4))


def co_duoi_nheo(m=DO, dai=2.2):
    """Cờ đuôi nheo; A tăng dần về đuôi cờ."""
    v = np.array([(0, 0, 0), (0, -.8, 0), (dai, -.4, 0)], float)
    c = np.tile(m, (3, 1))
    c[:, 3] = (0.0, 0.0, 1.0)
    return Hinh(v, [[0, 2, 1]], c=c)


def _vet_tau(z_duoi, dai, rong):
    """Vệt bọt sau đuôi tàu; A mờ dần về cuối, sáng ở hai mép."""
    hang, mau_vet = [], []
    for s in np.linspace(0, 1, 9):
        z = z_duoi - s * dai
        w = rong * .35 + s * rong
        hang.append([(-w, .3, z), (0, .3, z), (w, .3, z)])
        mo = (1 - s) ** 1.3
        mau_vet.append([(1, 1, 1, mo), (1, 1, 1, mo * .35), (1, 1, 1, mo)])
    hang = np.array(hang, float)
    return Hinh(hang.reshape(-1, 3), _luoi_khep(hang), c=np.array(mau_vet).reshape(-1, 4))


def tau_buom(mau_ngoai="#7b4322", mau_doc="#5e331a", mau_vien="#d9b45a", buom=(TRANG, DO), co=DO,
        mau_boong="#a87747", dau_lau=False, keo_vet=False):
    """Tàu ba cột buồm dài 17m."""
    lo = Lo()
    rng = np.random.default_rng(13)
    lo.them("mau", _than_tau(8.5, 2.5, -1.5, 1.6, mau(mau_ngoai), mau(mau_doc), mau(mau_vien)))
    for t in (.72, .1, -.55):
        z = t * 8.5
        boong = hop(4.4 * (1 - abs(t) ** 2.6) ** .7, .15, 2.4 if t != .1 else 8.2)
        y = 1.7 + (.45 if t < -.4 else 0) + (.1 if t > .6 else 0)
        lo.them("mau", boong.doi_mau(mau(mau_boong)), bien_doi((0, y, z)))
    cuoi = bien_doi((0, 2.6, -6.2))
    lo.them("mau", hop(3.8, 1.5, 3.2, .1).doi_mau(mau(mau_doc)), cuoi)
    for x in (-1.1, 0, 1.1):
        lo.them("phat_sang", hop(.5, .55, .08).doi_mau(mau("#ffd27a")), cuoi @ bien_doi((x, .1, -1.62)))
    for z, cao, rong in ((4.3, 13.0, 4.2), (-1.0, 16.0, 5.3), (-5.2, 11.0, 3.3)):
        lo.them("mau", ong([(0, 1.5, z), (0, cao, z)], np.linspace(.2, .07, 2), 10).doi_mau(GO_TOI))
        for y0, ti in ((cao * .47, 1.0), (cao * .8, .7)):
            lo.them("mau", ong([(-rong * ti * .55, y0 + 1.8, z), (rong * ti * .55, y0 + 1.8, z)], .06, 6).doi_mau(GO))
            lo.them("vai", _buom(rong * ti, 3.6 * ti, *buom), bien_doi((0, y0 - 1.2 * ti, z + .14)))
    lo.them("mau", ong([(0, 2.3, 8.5), (0, 4.3, 12.5)], .09, 6).doi_mau(GO_TOI))
    lo.them("vai", co_duoi_nheo(co), bien_doi((0, 16.0, -1.0)))
    for x in (-.8, .8):
        lo.them("kim", ong([(0, 4.2, 12.3), (x * 2.2, 2.0, 6)], .018, 4).doi_mau(DAY_THUNG))
    for x in (-1, 1):
        for k in range(5):
            lo.them("kim", ong([(x * 2.05, 1.05, -1.0 + k * 1.3), (x * 2.65, 1.1, -1.0 + k * 1.3)], .09, 8).doi_mau(mau("#2c2926")))
        lo.them("kim", ong([(0, 1.6, -1), (x * 2.6, 8.2, -1)], .017, 4).doi_mau(DAY_THUNG))
    if dau_lau:
        _dau_lau_tren_buom(lo, rng)
    if keo_vet:
        lo.them("vet_tau", _vet_tau(-8.3, 26.0, 4.0))
    return lo


def _dau_lau_tren_buom(lo, rng):
    """Đầu lâu xương chéo trên buồm giữa."""
    goc = bien_doi((0, 9.4, -.1))
    xuong = mau("#f4efe2")
    lo.them("mau", cuc(rng, 2, 0, det=(.62, .7, .12)).doi_mau(xuong), goc @ bien_doi((0, .45, 0)))
    for x in (-.24, .24):
        lo.them("mau", cuc(rng, 1, 0, det=(.14, .16, .05)).doi_mau(mau("#1c1a1a")), goc @ bien_doi((x, .5, .1)))
    for g in (.8, -.8):
        lo.them("mau", hop(2.4, .22, .1, .03).doi_mau(xuong), goc @ bien_doi((0, -.45, 0), xoay_z=g))


def tau_chien():
    """Tàu hạm đội: vỏ xanh hải quân, buồm trắng xanh."""
    return tau_buom("#1f3f73", "#183258", "#f2d16b", (TRANG, mau("#2f6fd9")), mau("#2f6fd9"), "#c9a877", keo_vet=True)


def tau_cuop():
    """Tàu cướp biển: vỏ đen, buồm than, cờ đen đầu lâu."""
    return tau_buom("#2a2320", "#1b1716", "#8f2a20", (mau("#2e2b2b"), mau("#413c3b")), mau("#141212"), "#4f4034",
            dau_lau=True, keo_vet=True)


def _nguoi(rng, mau_ao, mau_non="#e4c98a", ngoi=False):
    """Người nhỏ đội nón lá. Chân tại y = 0."""
    ds = []
    cao = .55 if ngoi else .85
    ds.append(tien([(.17, 0), (.24, cao * .45), (.2, cao), (0, cao + .02)], 12).doi_mau(mau_ao))
    ds.append(cuc(rng, 2, 0).duoi(bien_doi((0, cao + .17, 0), ty_le=.18)).doi_mau(mau("#f0c8a0")))
    ds.append(tien([(.42, cao + .24), (.04, cao + .5), (0, cao + .52)], 16).doi_mau(mau(mau_non)))
    for x in (-.27, .27):
        ds.append(ong([(x * .7, cao * .85, 0), (x, cao * .45, .08)], .05, 6).doi_mau(mau_ao))
    return ghep(ds)


def nguoi_dan(so):
    """Người dân đi bộ quanh quảng trường."""
    rng = np.random.default_rng(30 + so)
    mau_ao = ["#d9412f", "#2f8fd9", "#f2b632", "#7ed957"][so % 4]
    return {"mau": _nguoi(rng, mau(mau_ao))}


def thuyen_nho():
    """Thuyền chèo một người, hai mái chèo."""
    lo = Lo()
    rng = np.random.default_rng(31)
    lo.them("mau", _than_tau(2.2, .75, -.28, .32, mau("#b5763f"), mau("#9c6333"), mau("#f6efe0")))
    lo.them("mau", hop(1.1, .06, 3.2).doi_mau(mau("#8a5a33")), bien_doi((0, .12, 0)))
    lo.them("mau", _nguoi(rng, mau("#2f8fd9"), ngoi=True), bien_doi((0, .15, -.2)))
    for x in (-1, 1):
        lo.them("mau", ong([(x * .3, .55, -.1), (x * 1.5, -.15, .5)], .03, 5).doi_mau(GO))
    lo.them("vet_tau", _vet_tau(-2.0, 7.0, 1.0))
    return lo


def thuyen_buom_nho():
    """Thuyền buồm tam giác của dân chài."""
    lo = Lo()
    rng = np.random.default_rng(32)
    lo.them("mau", _than_tau(3.4, 1.05, -.45, .5, mau("#3f8f8a"), mau("#35777a"), mau("#f6efe0")))
    lo.them("mau", hop(1.5, .06, 4.6).doi_mau(GO), bien_doi((0, .3, 0)))
    lo.them("mau", ong([(0, .3, .6), (0, 6.2, .6)], np.linspace(.07, .03, 2), 8).doi_mau(GO_TOI))
    lo.them("mau", ong([(0, 1.2, .6), (0, 1.2, -3.0)], .04, 6).doi_mau(GO))
    tam_giac = np.array([(0, 1.3, .5), (.7, 3.2, -1.1), (0, 1.3, -2.9), (0, 6.0, .5)], float)
    c = np.tile(mau("#f27a3f"), (4, 1))
    c[:, 3] = (0.1, 1.0, 0.5, 0.2)
    lo.them("vai", Hinh(tam_giac, [[0, 1, 3], [0, 2, 1]], c=c))
    lo.them("mau", _nguoi(rng, mau("#f2b632"), ngoi=True), bien_doi((0, .33, -1.8)))
    lo.them("vet_tau", _vet_tau(-3.2, 11.0, 1.4))
    return lo


def thuyen_thung():
    """Thuyền thúng tròn, người ngồi câu cá."""
    lo = Lo()
    rng = np.random.default_rng(33)
    vong = [(.0, -.32), (.45, -.3), (.85, -.12), (1.02, .12), (1.05, .36)]
    hang = [mau("#8f6b3d") if k % 2 else mau("#a47f4a") for k in range(5)]
    lo.them("mau", tien(vong, 24, mau_hang=hang))
    lo.them("mau", nap(.98, .02, 24).doi_mau(mau("#6b4e2c")))
    lo.them("mau", tien([(1.03, .34), (1.1, .38), (1.03, .42)], 24).doi_mau(GO_TOI))
    lo.them("mau", _nguoi(rng, mau("#d9412f"), ngoi=True), bien_doi((0, .03, -.15)))
    lo.them("mau", ong([(.15, .6, .1), (1.2, 1.5, 1.6)], np.linspace(.025, .012, 2), 5).doi_mau(GO))
    lo.them("kim", ong([(1.2, 1.5, 1.6), (1.2, -.3, 1.7)], .006, 3).doi_mau(mau("#e8e8e8")))
    lo.them("mau", cuc(rng, 1, 0).doi_mau(DO), bien_doi((1.2, .05, 1.7), ty_le=.05))
    return lo


def ca_heo():
    """Cá heo mũi +z."""
    rng = np.random.default_rng(34)
    than = cuc(rng, 2, 0, det=(.3, .34, 1.0))
    t = np.clip((than.v[:, 1] + .34) / .68, 0, 1)[:, None]
    than = Hinh(than.v, than.i, than.n, mau("#d8e2ea") * (1 - t) + mau("#5f7f9c") * t)
    mom = cuc(rng, 1, 0, det=(.08, .07, .26)).duoi(bien_doi((0, -.05, 1.1))).doi_mau(mau("#8fa6ba"))
    vay = Hinh(np.array([(0, .28, .15), (0, .72, -.3), (0, .25, -.45)], float), [[0, 2, 1]], c=np.tile(mau("#4f6f8c"), (3, 1)))
    duoi = Hinh(np.array([(0, 0, -.9), (-.5, .02, -1.3), (.5, .02, -1.3)], float), [[0, 1, 2]], c=np.tile(mau("#4f6f8c"), (3, 1)))
    return {"kim": ghep([than, mom, vay, duoi])}


def cua():
    """Cua đỏ bò trên cát."""
    rng = np.random.default_rng(35)
    do = mau("#d9412f")
    ds = [cuc(rng, 2, .03, det=(.24, .1, .18)).duoi(bien_doi((0, .13, 0))).doi_mau(do)]
    for x in (-1, 1):
        for k in range(3):
            z = -.1 + k * .1
            ds.append(ong([(x * .2, .1, z), (x * .36, .1, z * 1.3), (x * .42, 0, z * 1.5)], .018, 5).doi_mau(do))
        ds.append(ong([(x * .2, .12, .12), (x * .34, .14, .26)], .03, 5).doi_mau(do))
        ds.append(cuc(rng, 1, 0).duoi(bien_doi((x * .34, .15, .3), ty_le=(.08, .06, .1))).doi_mau(do))
        ds.append(cuc(rng, 0, 0).duoi(bien_doi((x * .07, .24, .14), ty_le=.03)).doi_mau(mau("#141212")))
    return {"mau": ghep(ds)}


def buom_bay(so):
    """Bướm: hai cánh vỗ nhờ vật liệu `canh_buom`."""
    rng = np.random.default_rng(40 + so)
    m = mau(["#ff6f91", "#ffd23c", "#6fc3ff", "#c17bff", "#ff9f43"][so % 5])
    canh = []
    for phia in (-1, 1):
        v = np.array([(0, 0, .06), (phia * .2, 0, .14), (phia * .16, 0, -.08), (0, 0, -.06)], float)
        i = [[0, 2, 1], [0, 3, 2]] if phia > 0 else [[0, 1, 2], [0, 2, 3]]
        canh.append(Hinh(v, i, c=np.tile(m, (4, 1))))
    than = cuc(rng, 0, 0).duoi(bien_doi((0, 0, 0), ty_le=(.012, .012, .08))).doi_mau(mau("#2c2926"))
    return {"canh_buom": ghep([*canh, than])}


def khinh_khi_cau(m1, m2):
    """Khinh khí cầu sọc, giỏ ở y = 0."""
    lo = Lo()
    rng = np.random.default_rng(36)
    so_soc = 12
    soc = lambda a: np.where((np.floor(a / TAU * so_soc).astype(int) % 2 == 0)[:, None], m1[None], m2[None])
    bien = [(.7, 3.6), (1.5, 4.6), (2.9, 6.6), (3.6, 8.6), (3.5, 10.4), (2.6, 12.0), (1.2, 12.9), (0, 13.1)]
    lo.them("mau", tien(bien, 32, mau_goc=soc))
    lo.them("mau", hop(1.2, .85, 1.2, .08).doi_mau(mau("#a87747")), bien_doi((0, .42, 0)))
    for x in (-.5, .5):
        for z in (-.5, .5):
            lo.them("kim", ong([(x, .85, z), (x * 1.3, 3.65, z * 1.3)], .018, 4).doi_mau(GO_TOI))
    lo.them("mau", _nguoi(rng, mau("#f6efe0"), ngoi=True), bien_doi((0, .55, 0)))
    return lo


def vong_ngua():
    """Vòng ngựa gỗ, trục quay Y tại tâm."""
    lo = Lo()
    rng = np.random.default_rng(37)
    lo.them("mau", tien([(2.9, 0), (2.95, .18), (2.8, .28), (0, .28)], 40).doi_mau(mau("#f6efe0")))
    so_soc = 12
    soc = lambda a: np.where((np.floor(a / TAU * so_soc).astype(int) % 2 == 0)[:, None], DO[None], VANG[None])
    lo.them("mau", tien([(3.05, 3.2), (3.1, 3.5), (1.4, 4.4), (.3, 5.0), (0, 5.1)], 40, mau_goc=soc))
    lo.them("mau", nap(3.05, 3.2, 40, len_tren=False).doi_mau(mau("#ffe7a0")))
    lo.them("kim", tien([(.34, .28), (.28, 3.2)], 16).doi_mau(mau("#f2d16b")))
    lo.them("kim", cuc(rng, 2, 0).doi_mau(VANG), bien_doi((0, 5.2, 0), ty_le=.2))
    so_ngua = 8
    for k in range(so_ngua):
        a = k / so_ngua * TAU
        p = np.array([np.sin(a) * 2.2, 0, np.cos(a) * 2.2])
        lo.them("kim", ong([p + (0, .28, 0), p + (0, 3.2, 0)], .04, 6).doi_mau(mau("#f2d16b")))
        m = bien_doi(p + (0, 1.1 + (.2 if k % 2 else -.05), 0), a + np.pi / 2)
        _ngua(lo, rng, m, mau(["#f6efe0", "#c78f5a", "#f4a9b8", "#8ccbd4"][k % 4]))
    for k in range(20):
        a = k / 20 * TAU
        lo.them("phat_sang", cuc(rng, 1, 0).doi_mau(mau("#ffe7a0")),
                bien_doi((np.sin(a) * 3.08, 3.26, np.cos(a) * 3.08), ty_le=.07))
    return lo


def _ngua(lo, rng, m, mau_long):
    lo.them("mau", cuc(rng, 2, 0, det=(.22, .24, .58)).doi_mau(mau_long), m)
    lo.them("mau", ong([(0, .14, .42), (0, .6, .68)], np.linspace(.12, .09, 2), 8).doi_mau(mau_long), m)
    lo.them("mau", cuc(rng, 2, 0, det=(.11, .13, .24)).doi_mau(mau_long), m @ bien_doi((0, .64, .82)))
    lo.them("mau", ong([(0, .78, .62), (0, .5, .3), (0, .3, .05)], .05, 5).doi_mau(GO_TOI), m)
    for x in (-.13, .13):
        for z in (-.38, .38):
            lo.them("mau", ong([(x, -.12, z), (x, -.6, z + (.14 if z > 0 else -.14))], .045, 6).doi_mau(mau_long), m)


def phao():
    """Phao báo đèn."""
    lo = Lo()
    rng = np.random.default_rng(38)
    lo.them("mau", tien([(.1, -.5), (.75, -.15), (.75, .28), (.4, .55), (.1, 1.6), (.16, 1.72), (0, 1.8)], 20,
            mau_hang=[DO, DO, TRANG, DO, TRANG, DO, DO]))
    lo.them("phat_sang", cuc(rng, 1, 0).doi_mau(mau("#ff8a5c")), bien_doi((0, 1.95, 0), ty_le=.16))
    return lo
