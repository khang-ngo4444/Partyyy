"""Sinh nhạc + SFX placeholder vào asset/audio/ (xem asset/audio/README.md).

Chạy: python tool/tao_am_thanh_placeholder.py  (từ gốc project, cần ffmpeg trên PATH)
File đã có thì BỎ QUA để không đè file thật bạn đã thay; thêm --ghi-de để sinh lại hết.

Nhạc: tổng hợp chiptune đơn giản, mỗi trò một giọng/nhịp để nghe là biết đang phát đúng bộ.
SFX: chép từ bộ Kenney CC0 có sẵn trong asset/.
"""
import argparse
import math
import random
import shutil
import struct
import subprocess
import sys
import tempfile
import wave
from pathlib import Path

GOC = Path(__file__).resolve().parent.parent
THU_MUC_NHAC = GOC / "asset" / "audio" / "nhac"
THU_MUC_SFX = GOC / "asset" / "audio" / "sfx"
IMPACT = GOC / "asset" / "kenney_impact-sounds" / "Audio"
INTERFACE = GOC / "asset" / "kenney_interface-sounds" / "Audio"

TAN_SO_MAU = 22050
CHAT_LUONG_VORBIS = "1"
MIDI_LA4 = 69
HZ_LA4 = 440.0
SO_NOT_MOI_NHIP = 4
SO_NHIP_VONG_LAP = 8
GIAY_KET_QUA = 3.5
BIEN_DO = 0.32
THANG_TRUONG = (0, 2, 4, 5, 7, 9, 11)
THANG_THU = (0, 2, 3, 5, 7, 8, 10)
HOA_AM_TIEN_TRINH = (0, 3, 4, 3)

# ma: (nốt gốc MIDI, nhịp/phút, thang âm, dạng sóng)
BO_NHAC = {
	"menu": (62, 104, THANG_TRUONG, "tam_giac"),
	"ban_co": (60, 96, THANG_TRUONG, "tam_giac"),
	"tank_battle": (50, 132, THANG_THU, "vuong"),
	"breaking_blocks": (57, 124, THANG_THU, "tam_giac"),
	"laser_leap": (62, 148, THANG_THU, "rang_cua"),
	"spotlights": (53, 88, THANG_THU, "tam_giac"),
	"explosive": (55, 156, THANG_THU, "vuong"),
	"magma": (48, 112, THANG_THU, "rang_cua"),
	"crown": (65, 120, THANG_TRUONG, "vuong"),
	"word_wars": (67, 108, THANG_TRUONG, "tam_giac"),
	"dem_thu": (64, 100, THANG_TRUONG, "vuong"),
	"lo_da": (52, 140, THANG_THU, "tam_giac"),
	"toy_factory": (69, 128, THANG_TRUONG, "rang_cua"),
	"wave_hide": (59, 92, THANG_TRUONG, "tam_giac"),
	"minefield": (47, 104, THANG_THU, "vuong"),
	"paint": (72, 136, THANG_TRUONG, "tam_giac"),
}

# Bài chill của sảnh: nghe lâu nên viết riêng, không dùng chiptune chung.
BPM_CHILL = 72
PHACH_MOI_O_NHIP = 4
CHAT_LUONG_CHILL = "3"
# Tiếng kick chiếm đỉnh nên phải nâng biên độ thì bài mới to ngang các bản chiptune.
BIEN_DO_CHILL = 0.62
# (nốt gốc MIDI, các nốt hợp âm so với gốc, các bậc giai điệu so với gốc)
_FMAJ7 = (53, (12, 16, 19, 23), (12, 16, 19, 24))
_EM7 = (52, (12, 15, 19, 22), (12, 15, 19, 22))
_DM9 = (50, (12, 15, 19, 22, 26), (14, 17, 19, 24))
_CMAJ7 = (48, (12, 16, 19, 23), (16, 19, 24, 26))
_AM7 = (45, (12, 15, 19, 22), (15, 19, 22, 24))
_G7SUS = (43, (12, 17, 19, 22), (17, 19, 24, 26))
HOP_AM_CHILL = (_FMAJ7, _EM7, _DM9, _CMAJ7, _AM7, _DM9, _G7SUS, _CMAJ7) * 2

# Menu và bàn cờ chỉ có một bản, không có đếm ngược / kết quả.
CHI_CO_BAN_CHOI = {"menu", "ban_co"}

# Tiếng bấm gốc quá to so với mọi thứ còn lại nên hạ sẵn trong file.
GIAM_DB_SFX = {"bam_nut": 19}

# tên SFX: file nguồn Kenney
BO_SFX = {
	"bam_nut": INTERFACE / "drop_003.ogg",
	"chuyen_canh": INTERFACE / "maximize_008.ogg",
	"xuc_xac": IMPACT / "impactWood_light_001.ogg",
	"buoc_chan": IMPACT / "footstep_wood_000.ogg",
	"luot_moi": INTERFACE / "select_002.ogg",
	"nhan_tien": INTERFACE / "confirmation_001.ogg",
	"mat_mau": IMPACT / "impactSoft_medium_000.ogg",
	"nhan_cup": INTERFACE / "maximize_003.ogg",
	"dung_do": INTERFACE / "open_002.ogg",
	"thang_van": INTERFACE / "confirmation_004.ogg",
	"dem_nguoc": INTERFACE / "tick_001.ogg",
	"bat_dau": INTERFACE / "maximize_006.ogg",
	"thang": INTERFACE / "confirmation_002.ogg",
	"thua": INTERFACE / "error_006.ogg",
	"danh": IMPACT / "impactPunch_medium_000.ogg",
	"chuong": IMPACT / "impactPunch_heavy_000.ogg",
	"loai": IMPACT / "impactSoft_heavy_000.ogg",
	"ban": IMPACT / "impactMetal_heavy_000.ogg",
	"no": IMPACT / "impactPlate_heavy_000.ogg",
	"vo": IMPACT / "impactMining_000.ogg",
	"chuyen_bom": INTERFACE / "pluck_001.ogg",
	"doi_mien": INTERFACE / "bong_001.ogg",
	"go_chu": INTERFACE / "tick_004.ogg",
	"tra_loi": INTERFACE / "select_005.ogg",
	"ve_dich": INTERFACE / "confirmation_003.ogg",
	"phun": INTERFACE / "scratch_002.ogg",
	"laser": INTERFACE / "glitch_002.ogg",
	"song": INTERFACE / "question_002.ogg",
	"son": INTERFACE / "drop_002.ogg",
}


def tan_so(midi: int) -> float:
	return HZ_LA4 * 2.0 ** ((midi - MIDI_LA4) / 12.0)


def mau_song(dang: str, pha: float) -> float:
	pha %= 1.0
	if dang == "vuong":
		return 1.0 if pha < 0.5 else -1.0
	if dang == "rang_cua":
		return 2.0 * pha - 1.0
	return 4.0 * abs(pha - 0.5) - 1.0


def not_thang(goc: int, thang: tuple, bac: int) -> int:
	quang_tam, trong_thang = divmod(bac, len(thang))
	return goc + 12 * quang_tam + thang[trong_thang]


def them_not(dem: list, bat_dau: int, do_dai: int, midi: int, dang: str, am_luong: float) -> None:
	"""Cộng một nốt vào bộ đệm; fade đầu/cuối để không kêu tách, gói vòng để lặp liền mạch."""
	hz = tan_so(midi)
	fade = min(TAN_SO_MAU // 200, do_dai // 2)
	for i in range(do_dai):
		bao = min(1.0, i / fade, (do_dai - i) / fade) * math.exp(-1.8 * i / do_dai)
		vi_tri = (bat_dau + i) % len(dem)
		dem[vi_tri] += am_luong * bao * mau_song(dang, hz * i / TAN_SO_MAU)


def vong_lap(goc: int, bpm: int, thang: tuple, dang: str, ngau_nhien: random.Random, so_nhip: int) -> list:
	mau_moi_not = int(TAN_SO_MAU * 60.0 / bpm / SO_NOT_MOI_NHIP * 2)
	so_not = so_nhip * SO_NOT_MOI_NHIP
	dem = [0.0] * (mau_moi_not * so_not)
	for vi_tri in range(so_not):
		hop_am = HOA_AM_TIEN_TRINH[vi_tri // SO_NOT_MOI_NHIP % len(HOA_AM_TIEN_TRINH)]
		bat_dau = vi_tri * mau_moi_not
		if vi_tri % SO_NOT_MOI_NHIP == 0:
			them_not(dem, bat_dau, mau_moi_not * SO_NOT_MOI_NHIP, not_thang(goc - 12, thang, hop_am), "tam_giac", 0.6)
		if ngau_nhien.random() < 0.75:
			bac = hop_am + ngau_nhien.choice((0, 2, 4, 7))
			them_not(dem, bat_dau, mau_moi_not, not_thang(goc + 12, thang, bac), dang, 0.3)
	return dem


def ket_qua(goc: int, thang: tuple, dang: str) -> list:
	"""Câu nhạc ngắn đi lên rồi ngân, không lặp."""
	dem = [0.0] * int(TAN_SO_MAU * GIAY_KET_QUA)
	mau_moi_not = TAN_SO_MAU // 6
	for i, bac in enumerate((0, 2, 4, 7)):
		them_not(dem, i * mau_moi_not, mau_moi_not, not_thang(goc + 12, thang, bac), dang, 0.45)
	bat_dau_ngan = 4 * mau_moi_not
	for bac in (0, 2, 4):
		them_not(dem, bat_dau_ngan, len(dem) - bat_dau_ngan, not_thang(goc, thang, bac + 7), "tam_giac", 0.4)
	return dem


def not_dien_piano(dem: list, bat_dau: int, giay: float, midi: int, am_luong: float) -> None:
	"""Tiếng electric piano ấm: hoà âm bậc thấp tắt nhanh hơn âm gốc, gói vòng để lặp liền mạch."""
	hz = tan_so(midi)
	so_mau = int(giay * TAN_SO_MAU)
	buoc = 2.0 * math.pi * hz / TAN_SO_MAU
	for i in range(so_mau):
		t = i / TAN_SO_MAU
		tan = math.exp(-1.6 * t) * min(1.0, i / 220.0) * min(1.0, (so_mau - i) / 1500.0)
		goc = buoc * i
		mau = math.sin(goc + 0.35 * math.exp(-5.0 * t) * math.sin(goc * 2.0)) + 0.12 * math.exp(-3.0 * t) * math.sin(goc * 2.0)
		dem[(bat_dau + i) % len(dem)] += am_luong * tan * mau


def tieng_kick(dem: list, bat_dau: int, am_luong: float) -> None:
	for i in range(int(0.22 * TAN_SO_MAU)):
		t = i / TAN_SO_MAU
		pha = 2.0 * math.pi * (52.0 * t + 1.4 * (1.0 - math.exp(-30.0 * t)))
		dem[(bat_dau + i) % len(dem)] += am_luong * math.exp(-16.0 * t) * math.sin(pha)


def tieng_nhieu(dem: list, bat_dau: int, giay: float, am_luong: float, ngau_nhien: random.Random) -> None:
	"""Tiếng hi-hat/snare chổi: nhiễu ngắn, tắt nhanh."""
	so_mau = int(giay * TAN_SO_MAU)
	for i in range(so_mau):
		dem[(bat_dau + i) % len(dem)] += am_luong * math.exp(-6.0 * i / so_mau) * ngau_nhien.uniform(-1.0, 1.0)


def loc_thap_vong(dem: list, he_so: float) -> list:
	"""Lọc thông thấp một cực, chạy hai vòng để đầu và cuối bản khớp nhau khi lặp."""
	ra = [0.0] * len(dem)
	truoc = 0.0
	for _ in range(2):
		for i, mau in enumerate(dem):
			truoc += he_so * (mau - truoc)
			ra[i] = truoc
	return ra


def nhac_chill_sanh() -> list:
	"""Lo-fi chậm: hợp âm 7 trầm ấm, bass mềm, trống chổi, vài nốt giai điệu thưa."""
	ngau_nhien = random.Random("sanh-chill")
	mau_moi_phach = int(TAN_SO_MAU * 60.0 / BPM_CHILL)
	mau_moi_o = mau_moi_phach // 2
	so_o = len(HOP_AM_CHILL) * PHACH_MOI_O_NHIP * 2
	nhac = [0.0] * (so_o * mau_moi_o)
	trong = [0.0] * len(nhac)
	for nhip, (goc, not_hop_am, thang) in enumerate(HOP_AM_CHILL):
		dau_nhip = nhip * PHACH_MOI_O_NHIP * 2 * mau_moi_o
		# Rải nhẹ từ thấp lên để nghe như đánh tay, không dập đều một lúc.
		for i, nc in enumerate(not_hop_am):
			not_dien_piano(nhac, dau_nhip + i * int(0.018 * TAN_SO_MAU), 2.4, goc + nc, 0.2)
		if nhip % 2 == 1:
			not_dien_piano(nhac, dau_nhip + 5 * mau_moi_o, 1.2, goc + not_hop_am[1], 0.11)
		not_dien_piano(nhac, dau_nhip, 1.3, goc - 12, 0.3)
		not_dien_piano(nhac, dau_nhip + 5 * mau_moi_o, 0.8, goc - 12 + not_hop_am[2], 0.2)
		for phach in range(PHACH_MOI_O_NHIP):
			dau_phach = dau_nhip + phach * mau_moi_phach
			if phach in (0, 2):
				tieng_kick(trong, dau_phach, 0.32)
			if phach in (1, 3):
				tieng_nhieu(trong, dau_phach, 0.14, 0.07, ngau_nhien)
			# Swing nhẹ: nhịp móc đến trễ hơn một chút.
			tieng_nhieu(trong, dau_phach, 0.035, 0.022, ngau_nhien)
			tieng_nhieu(trong, dau_phach + int(mau_moi_o * 1.16), 0.03, 0.015, ngau_nhien)
		# Giai điệu thưa, chừa khoảng trống; ô nhịp cuối để nghỉ cho vòng lặp thở.
		if nhip < len(HOP_AM_CHILL) - 1:
			for o in (2, 3, 6):
				if ngau_nhien.random() < 0.42:
					not_dien_piano(nhac, dau_nhip + o * mau_moi_o, 1.5, 12 + goc + ngau_nhien.choice(thang), 0.13)
	nhac = loc_thap_vong(nhac, 0.3)
	return [a + b for a, b in zip(nhac, trong)]


def ghi_ogg(dem: list, dich: Path, chat_luong: str = CHAT_LUONG_VORBIS, bien_do: float = BIEN_DO) -> None:
	lon_nhat = max(max(abs(m) for m in dem), 1e-6)
	du_lieu = struct.pack("<%dh" % len(dem), *(int(m / lon_nhat * bien_do * 32767) for m in dem))
	dich.parent.mkdir(parents=True, exist_ok=True)
	with tempfile.TemporaryDirectory() as tam:
		wav = Path(tam) / "nhac.wav"
		with wave.open(str(wav), "wb") as f:
			f.setnchannels(1)
			f.setsampwidth(2)
			f.setframerate(TAN_SO_MAU)
			f.writeframes(du_lieu)
		subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", str(wav),
				"-c:a", "libvorbis", "-q:a", chat_luong, str(dich)], check=True)


def sinh_nhac(ghi_de: bool) -> int:
	so_file = 0
	dich_sanh = THU_MUC_NHAC / "sanh" / "choi.ogg"
	if ghi_de or not dich_sanh.exists():
		ghi_ogg(nhac_chill_sanh(), dich_sanh, CHAT_LUONG_CHILL, BIEN_DO_CHILL)
		so_file += 1
	for ma, (goc, bpm, thang, dang) in BO_NHAC.items():
		# Hạt giống cố định theo mã: chạy lại ra đúng giai điệu cũ.
		ngau_nhien = random.Random(ma)
		bo = {"choi": lambda: vong_lap(goc, bpm, thang, dang, ngau_nhien, SO_NHIP_VONG_LAP)}
		if ma not in CHI_CO_BAN_CHOI:
			bo["dem_nguoc"] = lambda: vong_lap(goc - 5, bpm, thang, "tam_giac", ngau_nhien, 2)
			bo["ket_qua"] = lambda: ket_qua(goc, thang, dang)
		for pha, tao in bo.items():
			dich = THU_MUC_NHAC / ma / (pha + ".ogg")
			if dich.exists() and not ghi_de:
				continue
			ghi_ogg(tao(), dich)
			so_file += 1
	return so_file


def chep_sfx(ghi_de: bool) -> int:
	THU_MUC_SFX.mkdir(parents=True, exist_ok=True)
	so_file = 0
	for ten, nguon in BO_SFX.items():
		dich = THU_MUC_SFX / (ten + ".ogg")
		if dich.exists() and not ghi_de:
			continue
		if ten in GIAM_DB_SFX:
			subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", str(nguon), "-af",
					"volume=-%ddB" % GIAM_DB_SFX[ten], "-c:a", "libvorbis", str(dich)], check=True)
		else:
			shutil.copyfile(nguon, dich)
		so_file += 1
	return so_file


def main() -> None:
	# Console Windows mặc định cp1252, in tiếng Việt sẽ văng lỗi.
	sys.stdout.reconfigure(encoding="utf-8")
	doc = argparse.ArgumentParser(description=__doc__)
	doc.add_argument("--ghi-de", action="store_true", help="sinh lại cả file đã có (mất file bạn đã thay)")
	tham_so = doc.parse_args()
	print("Nhạc mới: %d file" % sinh_nhac(tham_so.ghi_de))
	print("SFX mới: %d file" % chep_sfx(tham_so.ghi_de))


if __name__ == "__main__":
	main()
