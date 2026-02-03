import ctypes
import hashlib
import os
from ctypes import wintypes
from pathlib import Path

try:
    import win32api
    import win32con
    import win32gui
    import win32ui
    from PIL import Image

    HAS_WIN32 = True
except ImportError:
    HAS_WIN32 = False


class SHFILEINFO(ctypes.Structure):
    _fields_ = [
        ("hIcon", wintypes.HANDLE),
        ("iIcon", ctypes.c_int),
        ("dwAttributes", wintypes.DWORD),
        ("szDisplayName", wintypes.WCHAR * 260),
        ("szTypeName", wintypes.WCHAR * 80),
    ]


SHGFI_ICON = 0x100
SHGFI_LARGEICON = 0x000
SHIL_JUMBO = 0x4
SHIL_EXTRALARGE = 0x2


def get_cache_dir() -> Path:
    cache_dir = Path(__file__).parent.parent.parent / ".icon_cache"
    cache_dir.mkdir(exist_ok=True)
    return cache_dir


def get_cache_path(file_path: str) -> Path:
    path_hash = hashlib.md5(file_path.lower().encode()).hexdigest()[:16]
    return get_cache_dir() / f"{path_hash}.png"


def resolve_lnk_target(lnk_path: str) -> tuple[str, str, str]:
    if not HAS_WIN32:
        return lnk_path, "", ""
    try:
        import win32com.client

        shell = win32com.client.Dispatch("WScript.Shell")
        shortcut = shell.CreateShortCut(lnk_path)
        target = shortcut.TargetPath or lnk_path
        working_dir = shortcut.WorkingDirectory or ""
        icon_location = shortcut.IconLocation or ""
        return target, working_dir, icon_location
    except Exception:
        return lnk_path, "", ""


def extract_ico_best_size(ico_path: str, output_path: Path) -> bool:
    try:
        img = Image.open(ico_path)
        sizes = []

        if hasattr(img, "n_frames"):
            for i in range(img.n_frames):
                img.seek(i)
                sizes.append((img.size[0] * img.size[1], i, img.size))
        else:
            sizes.append((img.size[0] * img.size[1], 0, img.size))

        if not sizes:
            return False

        sizes.sort(reverse=True)
        best_frame = sizes[0][1]

        img.seek(best_frame)

        if img.mode != "RGBA":
            img = img.convert("RGBA")

        img.save(str(output_path), "PNG")
        return True
    except Exception as e:
        print(f"Error extracting ICO: {e}")
        return False


def get_jumbo_icon(file_path: str) -> int:
    if not HAS_WIN32:
        return 0
    try:
        shell32 = ctypes.windll.shell32

        class GUID(ctypes.Structure):
            _fields_ = [
                ("Data1", ctypes.c_ulong),
                ("Data2", ctypes.c_ushort),
                ("Data3", ctypes.c_ushort),
                ("Data4", ctypes.c_ubyte * 8),
            ]

        iid = GUID()
        iid.Data1 = 0x46EB5926
        iid.Data2 = 0x582E
        iid.Data3 = 0x4017
        iid.Data4 = (ctypes.c_ubyte * 8)(0x9F, 0xDF, 0xE8, 0x99, 0x8D, 0xAA, 0x09, 0x50)

        image_list = ctypes.c_void_p()
        hr = shell32.SHGetImageList(
            SHIL_JUMBO, ctypes.byref(iid), ctypes.byref(image_list)
        )

        if hr != 0 or not image_list:
            hr = shell32.SHGetImageList(
                SHIL_EXTRALARGE, ctypes.byref(iid), ctypes.byref(image_list)
            )

        if hr != 0 or not image_list:
            return 0

        shfi = SHFILEINFO()
        shell32.SHGetFileInfoW(
            file_path,
            0,
            ctypes.byref(shfi),
            ctypes.sizeof(shfi),
            SHGFI_ICON | 0x4000,
        )

        return shfi.iIcon
    except Exception:
        return 0


def extract_icon_from_handle(hicon: int, output_path: Path, size: int = 256) -> bool:
    if not HAS_WIN32 or not hicon:
        return False

    try:
        screen_dc = win32gui.GetDC(0)
        hdc = win32ui.CreateDCFromHandle(screen_dc)
        hbmp = win32ui.CreateBitmap()
        hbmp.CreateCompatibleBitmap(hdc, size, size)
        hdc_mem = hdc.CreateCompatibleDC()

        old_bmp = hdc_mem.SelectObject(hbmp)

        brush = win32gui.CreateSolidBrush(win32api.RGB(0, 0, 0))
        win32gui.FillRect(hdc_mem.GetHandleOutput(), (0, 0, size, size), brush)
        win32gui.DeleteObject(brush)

        win32gui.DrawIconEx(
            hdc_mem.GetHandleOutput(),
            0,
            0,
            hicon,
            size,
            size,
            0,
            None,
            win32con.DI_NORMAL,
        )

        hdc_mem.SelectObject(old_bmp)

        bmp_info = hbmp.GetInfo()
        bmp_str = hbmp.GetBitmapBits(True)

        img = Image.frombuffer(
            "RGBA",
            (bmp_info["bmWidth"], bmp_info["bmHeight"]),
            bmp_str,
            "raw",
            "BGRA",
            0,
            1,
        )

        img.save(str(output_path), "PNG")

        win32gui.DestroyIcon(hicon)
        hdc_mem.DeleteDC()
        win32gui.ReleaseDC(0, screen_dc)
        win32gui.DeleteObject(hbmp.GetHandle())

        return True

    except Exception as e:
        print(f"Error extracting icon from handle: {e}")
        return False


def extract_icon_from_exe(exe_path: str, output_path: Path, size: int = 256) -> bool:
    if not HAS_WIN32:
        return False

    try:
        large_icons, small_icons = win32gui.ExtractIconEx(exe_path, 0, 10)

        if not large_icons:
            return False

        hicon = large_icons[0]

        screen_dc = win32gui.GetDC(0)
        hdc = win32ui.CreateDCFromHandle(screen_dc)
        hbmp = win32ui.CreateBitmap()
        hbmp.CreateCompatibleBitmap(hdc, size, size)
        hdc_mem = hdc.CreateCompatibleDC()

        old_bmp = hdc_mem.SelectObject(hbmp)

        brush = win32gui.CreateSolidBrush(win32api.RGB(0, 0, 0))
        win32gui.FillRect(hdc_mem.GetHandleOutput(), (0, 0, size, size), brush)
        win32gui.DeleteObject(brush)

        win32gui.DrawIconEx(
            hdc_mem.GetHandleOutput(),
            0,
            0,
            hicon,
            size,
            size,
            0,
            None,
            win32con.DI_NORMAL,
        )

        hdc_mem.SelectObject(old_bmp)

        bmp_info = hbmp.GetInfo()
        bmp_str = hbmp.GetBitmapBits(True)

        img = Image.frombuffer(
            "RGBA",
            (bmp_info["bmWidth"], bmp_info["bmHeight"]),
            bmp_str,
            "raw",
            "BGRA",
            0,
            1,
        )

        img.save(str(output_path), "PNG")

        for icon in large_icons:
            try:
                win32gui.DestroyIcon(icon)
            except Exception:
                pass
        for icon in small_icons:
            try:
                win32gui.DestroyIcon(icon)
            except Exception:
                pass

        hdc_mem.DeleteDC()
        win32gui.ReleaseDC(0, screen_dc)
        win32gui.DeleteObject(hbmp.GetHandle())

        return True

    except Exception as e:
        print(f"Error extracting icon from {exe_path}: {e}")
        return False


def extract_icon(file_path: str) -> str:
    if not file_path or not HAS_WIN32:
        return ""

    path_obj = Path(file_path)

    if not path_obj.exists():
        return ""

    cache_path = get_cache_path(file_path)

    if cache_path.exists():
        return str(cache_path)

    suffix = path_obj.suffix.lower()

    if suffix == ".ico":
        if extract_ico_best_size(file_path, cache_path):
            return str(cache_path)

    target_path = file_path
    icon_path = ""

    if suffix == ".lnk":
        target_path, _, icon_location = resolve_lnk_target(file_path)
        if icon_location and "," in icon_location:
            icon_path = icon_location.split(",")[0].strip()
        if not target_path or not Path(target_path).exists():
            target_path = file_path

    if icon_path and Path(icon_path).exists():
        icon_suffix = Path(icon_path).suffix.lower()
        if icon_suffix == ".ico":
            if extract_ico_best_size(icon_path, cache_path):
                return str(cache_path)
        elif icon_suffix in (".exe", ".dll"):
            if extract_icon_from_exe(icon_path, cache_path, 256):
                return str(cache_path)

    target_obj = Path(target_path)
    target_suffix = target_obj.suffix.lower()

    if target_suffix == ".ico":
        if extract_ico_best_size(target_path, cache_path):
            return str(cache_path)

    if target_suffix in (".exe", ".dll"):
        if extract_icon_from_exe(target_path, cache_path, 256):
            return str(cache_path)

    if suffix == ".lnk":
        if extract_icon_from_exe(file_path, cache_path, 256):
            return str(cache_path)

    shfi = SHFILEINFO()
    shell32 = ctypes.windll.shell32
    result = shell32.SHGetFileInfoW(
        file_path,
        0,
        ctypes.byref(shfi),
        ctypes.sizeof(shfi),
        SHGFI_ICON | SHGFI_LARGEICON,
    )
    if result and shfi.hIcon:
        if extract_icon_from_handle(shfi.hIcon, cache_path, 48):
            return str(cache_path)

    return ""


def get_icon_url(file_path: str) -> str:
    extracted = extract_icon(file_path)
    if extracted:
        return f"file:///{extracted.replace(os.sep, '/')}"
    return ""


def get_lnk_info(lnk_path: str) -> dict:
    target, working_dir, icon_location = resolve_lnk_target(lnk_path)
    return {
        "target": target,
        "workingDir": working_dir,
        "iconLocation": icon_location,
    }
