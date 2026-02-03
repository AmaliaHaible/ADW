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


def get_cache_dir() -> Path:
    cache_dir = Path(__file__).parent.parent.parent / ".icon_cache"
    cache_dir.mkdir(exist_ok=True)
    return cache_dir


def get_cache_path(file_path: str) -> Path:
    path_hash = hashlib.md5(file_path.lower().encode()).hexdigest()[:16]
    return get_cache_dir() / f"{path_hash}.png"


def resolve_lnk_target(lnk_path: str) -> str:
    if not HAS_WIN32:
        return lnk_path
    try:
        import win32com.client

        shell = win32com.client.Dispatch("WScript.Shell")
        shortcut = shell.CreateShortCut(lnk_path)
        return shortcut.TargetPath or lnk_path
    except Exception:
        return lnk_path


def get_shell_icon(file_path: str) -> int:
    if not HAS_WIN32:
        return 0
    try:
        shell32 = ctypes.windll.shell32
        shfi = SHFILEINFO()
        result = shell32.SHGetFileInfoW(
            file_path,
            0,
            ctypes.byref(shfi),
            ctypes.sizeof(shfi),
            SHGFI_ICON | SHGFI_LARGEICON,
        )
        if result and shfi.hIcon:
            return shfi.hIcon
    except Exception:
        pass
    return 0


def extract_icon_from_handle(hicon: int, output_path: Path, size: int = 48) -> bool:
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

    try:
        hdc = win32ui.CreateDCFromHandle(win32gui.GetDC(0))
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
        win32gui.ReleaseDC(0, hdc.GetHandleOutput())
        hbmp.DeleteObject()

        return True

    except Exception as e:
        print(f"Error extracting icon from handle: {e}")
        return False


def extract_icon_from_exe(exe_path: str, output_path: Path, size: int = 48) -> bool:
    if not HAS_WIN32:
        return False

    try:
        large_icons, small_icons = win32gui.ExtractIconEx(exe_path, 0, 1)

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

        win32gui.DestroyIcon(hicon)
        for icon in small_icons:
            win32gui.DestroyIcon(icon)

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

    hicon = get_shell_icon(file_path)
    if hicon and extract_icon_from_handle(hicon, cache_path):
        return str(cache_path)

    target_path = file_path
    if path_obj.suffix.lower() == ".lnk":
        target_path = resolve_lnk_target(file_path)
        if not target_path or not Path(target_path).exists():
            target_path = file_path

    target_obj = Path(target_path)

    if target_obj.suffix.lower() in (".exe", ".dll", ".ico"):
        if extract_icon_from_exe(target_path, cache_path):
            return str(cache_path)

    if path_obj.suffix.lower() == ".lnk":
        if extract_icon_from_exe(file_path, cache_path):
            return str(cache_path)

    return ""


def get_icon_url(file_path: str) -> str:
    extracted = extract_icon(file_path)
    if extracted:
        return f"file:///{extracted.replace(os.sep, '/')}"
    return ""
