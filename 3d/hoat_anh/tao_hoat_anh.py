"""Dựng các clip riêng của PartyBash trên rig KayKit Medium thành Rig_Medium_Party.glb.

    python 3d/hoat_anh/tao_hoat_anh.py      # chạy ở gốc PartyBash; cần numpy

KayKit đã có chạy, nhảy, ném, cổ vũ...; file này chỉ thêm những động tác pack không có.
Mỗi tư thế xuất phát từ khung đầu của Idle_A rồi cộng góc xoay theo trục của nhân vật:
  x âm: đưa tay/chân ra trước, x dương: cúi người, gập gối và cẳng chân ra sau.
  z dương: đưa sang +x (phía tay trái nhân vật). Nhân vật nhìn về +z.
Xoay của khớp con tính như khi khớp cha chưa xoay, rồi đi theo khớp cha.
Nhân vật chibi đầu to, tay ngắn: giơ tay thẳng đứng sẽ khuất sau đầu, nên giơ chếch ra hai bên.
Clip đọc vào game qua `player/kaykit_animations.gd`.
"""
import json
import math
import os
import struct

import numpy as np

GOC = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
NGUON = os.path.join(GOC, "asset", "KayKit_Character_Animations_1.1_FREE", "Animations", "gltf", "Rig_Medium",
        "Rig_Medium_General.glb")
RA = os.path.join(GOC, "asset", "generated", "hoat_anh", "Rig_Medium_Party.glb")
KHUNG_MOI_GIAY = 30
TAU = math.tau


# ───────────────────────────── quaternion [x, y, z, w] ─────────────────────────────


def q_nhan(a, b):
    ax, ay, az, aw = a
    bx, by, bz, bw = b
    return np.array([aw * bx + ax * bw + ay * bz - az * by, aw * by - ax * bz + ay * bw + az * bx,
            aw * bz + ax * by - ay * bx + az * bw, aw * bw - ax * bx - ay * by - az * bz])


def q_lien_hop(q):
    return np.array([-q[0], -q[1], -q[2], q[3]])


def q_truc(truc, do):
    nua = math.radians(do) * 0.5
    return np.array([*(np.array(truc) * math.sin(nua)), math.cos(nua)])


def q_euler(x=0.0, y=0.0, z=0.0):
    return q_nhan(q_nhan(q_truc((0, 1, 0), y), q_truc((1, 0, 0), x)), q_truc((0, 0, 1), z))


# ───────────────────────────── đọc rig nguồn ─────────────────────────────


def doc_glb(duong):
    d = open(duong, "rb").read()
    dai_json = struct.unpack("<I", d[12:16])[0]
    goc = json.loads(d[20:20 + dai_json])
    dau_bin = 20 + dai_json + 8
    return goc, d[dau_bin:]


def doc_accessor(goc, nhi, chi_so):
    a = goc["accessors"][chi_so]
    v = goc["bufferViews"][a["bufferView"]]
    so_thanh_phan = {"SCALAR": 1, "VEC3": 3, "VEC4": 4}[a["type"]]
    dau = v.get("byteOffset", 0) + a.get("byteOffset", 0)
    return np.frombuffer(nhi, np.float32, a["count"] * so_thanh_phan, dau).reshape(-1, so_thanh_phan)


def tu_the_goc(goc, nhi):
    """Khung đầu của Idle_A: {bone: rotation}, cộng translation của hips."""
    ten = [n["name"] for n in goc["nodes"]]
    xoay = {n["name"]: np.array(n.get("rotation", (0, 0, 0, 1)), float) for n in goc["nodes"]}
    hips = np.array(goc["nodes"][ten.index("hips")]["translation"], float)
    clip = next(a for a in goc["animations"] if a["name"] == "Idle_A")
    for kenh in clip["channels"]:
        bo = ten[kenh["target"]["node"]]
        giatri = doc_accessor(goc, nhi, clip["samplers"][kenh["sampler"]]["output"])[0]
        if kenh["target"]["path"] == "rotation":
            xoay[bo] = np.array(giatri, float)
        elif kenh["target"]["path"] == "translation" and bo == "hips":
            hips = np.array(giatri, float)
    return xoay, hips


def xoay_toan_cuc(goc, xoay):
    """Xoay toàn cục của từng xương ở tư thế gốc, tính từ `root` xuống."""
    nodes = goc["nodes"]
    ra = {}

    def di(i, cha):
        ten = nodes[i]["name"]
        ra[ten] = q_nhan(cha, xoay.get(ten, np.array((0, 0, 0, 1.0))))
        for con in nodes[i].get("children", []):
            di(con, ra[ten])

    goc_root = next(i for i, n in enumerate(nodes) if n["name"] == "root")
    di(goc_root, np.array((0, 0, 0, 1.0)))
    return ra


# ───────────────────────────── các clip ─────────────────────────────
# Mỗi clip: (giây một vòng, lặp?, hàm(pha 0..1) -> ({bone: (x, y, z)}, (dx, dy, dz) của hips)).


def _chan_chay(p, bien=48.0):
    """Hai chân chạy: gối gập nhiều khi chân đang đưa ra sau."""
    s = math.sin(p * TAU)
    return {"upperleg.l": (-s * bien, 0, 0), "upperleg.r": (s * bien, 0, 0),
            "lowerleg.l": (35 + 35 * s, 0, 0), "lowerleg.r": (35 - 35 * s, 0, 0)}


def nhay_mua(p):
    s, c = math.sin(p * TAU), math.cos(p * TAU)
    nhac = abs(math.sin(p * TAU))
    khop = {"spine": (0, s * 14, s * 7), "chest": (6, s * 10, s * 7), "head": (c * 8, -s * 18, -s * 6),
            "upperarm.l": (-30, 0, 86 + 20 * s), "upperarm.r": (-30, 0, -86 + 20 * s),
            "lowerarm.l": (-30 + 25 * c, 0, 22), "lowerarm.r": (-30 - 25 * c, 0, -22),
            "upperleg.l": (-32 * max(s, 0), 0, 8), "lowerleg.l": (58 * max(s, 0), 0, 0),
            "upperleg.r": (-32 * max(-s, 0), 0, -8), "lowerleg.r": (58 * max(-s, 0), 0, 0)}
    return khop, (s * 0.05, -0.04 * (1 - nhac), 0)


def nhay_thang_cuoc(p):
    nay = abs(math.sin(p * TAU))
    vung = math.sin(p * 2 * TAU)
    khop = {"chest": (-10 * nay, 0, 0), "head": (-14 * nay, 0, 0),
            "upperarm.l": (-38, 0, 92 + 14 * vung), "upperarm.r": (-38, 0, -92 - 14 * vung),
            "lowerarm.l": (-14, 0, 18), "lowerarm.r": (-14, 0, -18),
            "upperleg.l": (-35 * (1 - nay), 0, 6), "upperleg.r": (-35 * (1 - nay), 0, -6),
            "lowerleg.l": (65 * (1 - nay), 0, 0), "lowerleg.r": (65 * (1 - nay), 0, 0)}
    return khop, (0, 0.3 * nay - 0.1 * (1 - nay), 0)


def thua_cuoc(p):
    tho = math.sin(p * TAU)
    khop = {"spine": (14, 0, 0), "chest": (18 + 3 * tho, 0, 0), "head": (12 - 3 * tho, 0, 0),
            "upperarm.l": (12, 0, -6), "upperarm.r": (12, 0, 6), "lowerarm.l": (-8, 0, 0), "lowerarm.r": (-8, 0, 0),
            "upperleg.l": (-14, 0, 2), "upperleg.r": (-14, 0, -2), "lowerleg.l": (24, 0, 0), "lowerleg.r": (24, 0, 0)}
    return khop, (0, -0.05 + 0.008 * tho, 0)


def choang_vang(p):
    s, c = math.sin(p * TAU), math.cos(p * TAU)
    khop = {"spine": (5 * c, 0, 9 * s), "chest": (6 * c, 0, 8 * s), "head": (16 * c, 0, 20 * s),
            "upperarm.l": (0, 0, 22 + 16 * s), "upperarm.r": (0, 0, -22 + 16 * s),
            "lowerarm.l": (-18, 0, 0), "lowerarm.r": (-18, 0, 0),
            "upperleg.l": (-8 + 10 * s, 0, 0), "upperleg.r": (-8 - 10 * s, 0, 0),
            "lowerleg.l": (14 - 10 * s, 0, 0), "lowerleg.r": (14 + 10 * s, 0, 0)}
    return khop, (0.05 * s, -0.025, 0.05 * c)


def nong_chan(p):
    s = math.sin(p * TAU)
    nay = abs(math.sin(p * TAU))
    khop = {"chest": (8, s * 10, 0), "head": (-6, -s * 14, 0),
            "upperleg.l": (-68 * max(s, 0), 0, 0), "lowerleg.l": (90 * max(s, 0), 0, 0),
            "upperleg.r": (-68 * max(-s, 0), 0, 0), "lowerleg.r": (90 * max(-s, 0), 0, 0),
            "upperarm.l": (0, 0, 70 + 30 * math.sin(p * 2 * TAU)), "upperarm.r": (0, 0, -70 - 30 * math.sin(p * 2 * TAU)),
            "lowerarm.l": (-30, 0, 0), "lowerarm.r": (-30, 0, 0)}
    return khop, (0, 0.12 * nay, 0)


def chay_hoang(p):
    s = math.sin(p * TAU)
    vung = math.sin(p * 2 * TAU)
    khop = {"spine": (10, s * 8, 0), "chest": (10, s * 8, 0), "head": (-16, -s * 12, 0),
            "upperarm.l": (-28 - 18 * s, 0, 90 + 18 * vung), "upperarm.r": (-28 + 18 * s, 0, -90 + 18 * vung),
            "lowerarm.l": (-22 + 20 * vung, 0, 20), "lowerarm.r": (-22 - 20 * vung, 0, -20)}
    khop.update(_chan_chay(p))
    return khop, (0, 0.05 * abs(math.cos(p * TAU)), 0)


def giu_thang_bang(p):
    s = math.sin(p * TAU)
    khop = {"spine": (0, 0, 12 * s), "chest": (0, 0, 8 * s), "head": (0, 0, -14 * s),
            "upperarm.l": (0, 0, 86 + 24 * s), "upperarm.r": (0, 0, -86 + 24 * s),
            "lowerarm.l": (-8, 0, 0), "lowerarm.r": (-8, 0, 0),
            "upperleg.l": (-22 * max(s, 0), 0, 12 * max(s, 0)), "lowerleg.l": (34 * max(s, 0), 0, 0),
            "upperleg.r": (-22 * max(-s, 0), 0, -12 * max(-s, 0)), "lowerleg.r": (34 * max(-s, 0), 0, 0)}
    return khop, (-0.05 * s, 0, 0)


def _tay_om_truoc_mat(p):
    run = math.sin(p * 2 * TAU) * 4
    return {"head": (-8, 0, 0), "upperarm.l": (-98 + run, 0, 44), "upperarm.r": (-98 + run, 0, -44),
            "lowerarm.l": (-48, 0, -24), "lowerarm.r": (-48, 0, 24)}


def do_bom_dung(p):
    khop = _tay_om_truoc_mat(p)
    khop.update({"upperleg.l": (-6, 0, 3), "upperleg.r": (-6, 0, -3), "lowerleg.l": (10, 0, 0), "lowerleg.r": (10, 0, 0)})
    return khop, (0, -0.01 + 0.012 * math.sin(p * TAU), 0)


def do_bom_chay(p):
    khop = _tay_om_truoc_mat(p)
    khop.update(_chan_chay(p, 44.0))
    khop.update({"chest": (10, 0, 0), "spine": (6, 0, 0)})
    return khop, (0, 0.05 * abs(math.cos(p * TAU)), 0)


CLIP = {
    "dance": (1.3, True, nhay_mua),
    "victory": (0.9, True, nhay_thang_cuoc),
    "defeat": (2.6, True, thua_cuoc),
    "dizzy": (1.5, True, choang_vang),
    "hot_feet": (0.42, True, nong_chan),
    "panic_run": (0.46, True, chay_hoang),
    "balance": (1.8, True, giu_thang_bang),
    "carry_idle": (0.8, True, do_bom_dung),
    "carry_run": (0.46, True, do_bom_chay),
}


# ───────────────────────────── ghi .glb ─────────────────────────────


def lay_mau(ham, giay, xoay_goc, hips_goc, xoay_cuc):
    """Trả (thời gian, {bone: quaternion theo khung}, translation hips theo khung)."""
    so_khung = max(int(round(giay * KHUNG_MOI_GIAY)), 2) + 1
    gio = np.linspace(0, giay, so_khung, dtype=np.float32)
    xoay_kenh, hips = {}, []
    for k in range(so_khung):
        khop, lech = ham(k / (so_khung - 1))
        hips.append(hips_goc + np.array(lech))
        for bo, goc_do in khop.items():
            g = xoay_cuc[bo]
            cuc_bo = q_nhan(q_nhan(q_lien_hop(g), q_euler(*goc_do)), g)
            xoay_kenh.setdefault(bo, []).append(q_nhan(xoay_goc[bo], cuc_bo))
    return gio, xoay_kenh, np.array(hips, np.float32)


def them_khoi(goc, nhi, mang, kieu, co_bien=False):
    """Thêm một accessor float vào cuối buffer."""
    while len(nhi) % 4:
        nhi.append(0)
    raw = np.asarray(mang, np.float32).tobytes()
    goc["bufferViews"].append({"buffer": 0, "byteOffset": len(nhi), "byteLength": len(raw)})
    nhi.extend(raw)
    a = {"bufferView": len(goc["bufferViews"]) - 1, "componentType": 5126,
            "count": len(mang), "type": kieu}
    if co_bien:
        a["min"] = [float(np.min(mang))]
        a["max"] = [float(np.max(mang))]
    goc["accessors"].append(a)
    return len(goc["accessors"]) - 1


def bo_du_lieu_clip_cu(goc, nhi):
    """Xoá clip cũ khỏi buffer, chỉ giữ bufferView mà mesh và skin còn dùng."""
    con_dung = set()
    for mesh in goc["meshes"]:
        for prim in mesh["primitives"]:
            con_dung.update(prim["attributes"].values())
            con_dung.add(prim["indices"])
    for skin in goc["skins"]:
        con_dung.add(skin["inverseBindMatrices"])
    moi_acc, doi_acc, moi_view, doi_view, buf = [], {}, [], {}, bytearray()
    for chi_so in sorted(con_dung):
        a = dict(goc["accessors"][chi_so])
        v = a["bufferView"]
        if v not in doi_view:
            view = dict(goc["bufferViews"][v])
            while len(buf) % 4:
                buf.append(0)
            dau = view.get("byteOffset", 0)
            view["byteOffset"] = len(buf)
            buf.extend(nhi[dau:dau + view["byteLength"]])
            doi_view[v] = len(moi_view)
            moi_view.append(view)
        a["bufferView"] = doi_view[v]
        doi_acc[chi_so] = len(moi_acc)
        moi_acc.append(a)
    for mesh in goc["meshes"]:
        for prim in mesh["primitives"]:
            prim["attributes"] = {k: doi_acc[v] for k, v in prim["attributes"].items()}
            prim["indices"] = doi_acc[prim["indices"]]
    for skin in goc["skins"]:
        skin["inverseBindMatrices"] = doi_acc[skin["inverseBindMatrices"]]
    goc["accessors"], goc["bufferViews"] = moi_acc, moi_view
    goc.pop("animations", None)
    return buf


def main():
    goc, nhi_goc = doc_glb(NGUON)
    xoay, hips = tu_the_goc(goc, nhi_goc)
    xoay_cuc = xoay_toan_cuc(goc, xoay)
    ten_node = {n["name"]: i for i, n in enumerate(goc["nodes"])}
    nhi = bo_du_lieu_clip_cu(goc, nhi_goc)
    hoat_anh = []
    for ten, (giay, _lap, ham) in CLIP.items():
        gio, kenh_xoay, kenh_hips = lay_mau(ham, giay, xoay, hips, xoay_cuc)
        vao = them_khoi(goc, nhi, gio.reshape(-1, 1), "SCALAR", True)
        samplers, channels = [], []
        for bo, gia_tri in kenh_xoay.items():
            samplers.append({"input": vao, "output": them_khoi(goc, nhi, gia_tri, "VEC4")})
            channels.append({"sampler": len(samplers) - 1, "target": {"node": ten_node[bo], "path": "rotation"}})
        samplers.append({"input": vao, "output": them_khoi(goc, nhi, kenh_hips, "VEC3")})
        channels.append({"sampler": len(samplers) - 1, "target": {"node": ten_node["hips"], "path": "translation"}})
        hoat_anh.append({"name": ten, "samplers": samplers, "channels": channels})
    goc["animations"] = hoat_anh
    while len(nhi) % 4:
        nhi.append(0)
    goc["buffers"] = [{"byteLength": len(nhi)}]
    js = json.dumps(goc, separators=(",", ":")).encode()
    js += b" " * (-len(js) % 4)
    os.makedirs(os.path.dirname(RA), exist_ok=True)
    with open(RA, "wb") as f:
        f.write(struct.pack("<III", 0x46546C67, 2, 28 + len(js) + len(nhi)))
        f.write(struct.pack("<II", len(js), 0x4E4F534A) + js)
        f.write(struct.pack("<II", len(nhi), 0x004E4942) + nhi)
    print(f"{RA}: {len(CLIP)} clip, {os.path.getsize(RA) // 1024} KB")


if __name__ == "__main__":
    main()
