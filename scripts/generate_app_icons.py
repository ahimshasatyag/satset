"""
Script untuk membuat file icon aplikasi:
- Windows (.ico multi-resolusi 16x16 hingga 256x256)
- Android Adaptive Icons (Foreground 108dp canvas, Background, dan XML v26)
- Android Legacy & Round Icons (ic_launcher.png dan ic_launcher_round.png)
- Web Favicon & PWA Icons
- iOS & macOS Icons
Berdasarkan master image LogoSatset.png menggunakan filter interpolasi LANCZOS.
"""

from PIL import Image, ImageDraw
import os

def create_rounded_icon(base_img, size, radius_ratio=0.22, padding_ratio=0.10):
    """Membuat icon persegi rounded dengan latar putih bersih"""
    w, h = size
    canvas = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(canvas)
    
    # Gambar rounded rectangle putih
    radius = int(w * radius_ratio)
    draw.rounded_rectangle([(0, 0), (w - 1, h - 1)], radius=radius, fill=(255, 255, 255, 255))
    
    # Tempel logo di tengah dengan padding aman
    pad = int(w * padding_ratio)
    inner_w = w - (pad * 2)
    inner_h = h - (pad * 2)
    logo_resized = base_img.resize((inner_w, inner_h), Image.Resampling.LANCZOS)
    canvas.paste(logo_resized, (pad, pad), logo_resized)
    return canvas

def create_circle_icon(base_img, size, padding_ratio=0.12):
    """Membuat icon lingkaran (round) dengan latar putih bersih"""
    w, h = size
    canvas = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(canvas)
    
    # Gambar lingkaran putih
    draw.ellipse([(0, 0), (w - 1, h - 1)], fill=(255, 255, 255, 255))
    
    # Tempel logo di tengah
    pad = int(w * padding_ratio)
    inner_w = w - (pad * 2)
    inner_h = h - (pad * 2)
    logo_resized = base_img.resize((inner_w, inner_h), Image.Resampling.LANCZOS)
    canvas.paste(logo_resized, (pad, pad), logo_resized)
    return canvas

def create_adaptive_foreground(base_img, size, safe_zone_ratio=0.66):
    """Membuat foreground adaptive icon (108dp canvas dengan safe-zone 72dp di tengah)"""
    w, h = size
    canvas = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    inner_size = int(w * safe_zone_ratio)
    offset = (w - inner_size) // 2
    logo_resized = base_img.resize((inner_size, inner_size), Image.Resampling.LANCZOS)
    canvas.paste(logo_resized, (offset, offset), logo_resized)
    return canvas

def generate_icons():
    src_path = os.path.join('assets', 'images', 'LogoSatset.png')
    if not os.path.exists(src_path):
        print(f"File sumber tidak ditemukan: {src_path}")
        return

    base_img = Image.open(src_path).convert('RGBA')

    # =========================================================================
    # 1. Windows ICO (Multi-resolusi 16x16 - 256x256)
    # =========================================================================
    ico_sizes = [(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)]
    ico_targets = [
        os.path.join('windows', 'runner', 'resources', 'app_icon.ico'),
        os.path.join('assets', 'images', 'app_icon.ico'),
        os.path.join('assets', 'icon', 'app_icon.ico'),
    ]
    for target in ico_targets:
        os.makedirs(os.path.dirname(target), exist_ok=True)
        base_img.save(target, format='ICO', sizes=ico_sizes)
        print(f"Berhasil membuat ICO: {target} ({os.path.getsize(target)} bytes)")

    # =========================================================================
    # 2. Android Icons (Legacy, Round, and Adaptive Foreground)
    # =========================================================================
    densities = {
        'mipmap-mdpi': {'icon': (48, 48), 'fg': (108, 108)},
        'mipmap-hdpi': {'icon': (72, 72), 'fg': (162, 162)},
        'mipmap-xhdpi': {'icon': (96, 96), 'fg': (216, 216)},
        'mipmap-xxhdpi': {'icon': (144, 144), 'fg': (324, 324)},
        'mipmap-xxxhdpi': {'icon': (192, 192), 'fg': (432, 432)},
    }
    
    for density, sizes in densities.items():
        dir_path = os.path.join('android', 'app', 'src', 'main', 'res', density)
        os.makedirs(dir_path, exist_ok=True)
        
        # a. Legacy Standard Icon (ic_launcher.png)
        launcher_icon = create_rounded_icon(base_img, sizes['icon'])
        launcher_icon.save(os.path.join(dir_path, 'ic_launcher.png'), 'PNG')
        
        # b. Round Icon (ic_launcher_round.png)
        round_icon = create_circle_icon(base_img, sizes['icon'])
        round_icon.save(os.path.join(dir_path, 'ic_launcher_round.png'), 'PNG')
        
        # c. Adaptive Foreground Icon (ic_launcher_foreground.png)
        fg_icon = create_adaptive_foreground(base_img, sizes['fg'])
        fg_icon.save(os.path.join(dir_path, 'ic_launcher_foreground.png'), 'PNG')
        
        print(f"Berhasil membuat Android {density}: icon={sizes['icon']}, fg={sizes['fg']}")

    # Pastikan Adaptive XML dan Colors tersedia
    v26_dir = os.path.join('android', 'app', 'src', 'main', 'res', 'mipmap-anydpi-v26')
    os.makedirs(v26_dir, exist_ok=True)
    xml_content = """<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
</adaptive-icon>
"""
    with open(os.path.join(v26_dir, 'ic_launcher.xml'), 'w', encoding='utf-8') as f:
        f.write(xml_content)
    with open(os.path.join(v26_dir, 'ic_launcher_round.xml'), 'w', encoding='utf-8') as f:
        f.write(xml_content)

    val_dir = os.path.join('android', 'app', 'src', 'main', 'res', 'values')
    os.makedirs(val_dir, exist_ok=True)
    with open(os.path.join(val_dir, 'colors.xml'), 'w', encoding='utf-8') as f:
        f.write("""<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">#FFFFFF</color>
</resources>
""")

    # =========================================================================
    # 3. Web Favicon & PWA Icons
    # =========================================================================
    web_targets = {
        'web/favicon.png': (48, 48),
        'web/icons/Icon-192.png': (192, 192),
        'web/icons/Icon-512.png': (512, 512),
        'web/icons/Icon-maskable-192.png': (192, 192),
        'web/icons/Icon-maskable-512.png': (512, 512),
    }
    for rel_path, size in web_targets.items():
        path = os.path.normpath(rel_path)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        resized = create_rounded_icon(base_img, size, radius_ratio=0.20, padding_ratio=0.10)
        resized.save(path, 'PNG')
        print(f"Berhasil membuat Web icon: {path} {size}")

    # =========================================================================
    # 4. iOS App Icons
    # =========================================================================
    ios_dir = os.path.join('ios', 'Runner', 'Assets.xcassets', 'AppIcon.appiconset')
    ios_targets = {
        'Icon-App-1024x1024@1x.png': (1024, 1024),
        'Icon-App-20x20@1x.png': (20, 20),
        'Icon-App-20x20@2x.png': (40, 40),
        'Icon-App-20x20@3x.png': (60, 60),
        'Icon-App-29x29@1x.png': (29, 29),
        'Icon-App-29x29@2x.png': (58, 58),
        'Icon-App-29x29@3x.png': (87, 87),
        'Icon-App-40x40@1x.png': (40, 40),
        'Icon-App-40x40@2x.png': (80, 80),
        'Icon-App-40x40@3x.png': (120, 120),
        'Icon-App-60x60@2x.png': (120, 120),
        'Icon-App-60x60@3x.png': (180, 180),
        'Icon-App-76x76@1x.png': (76, 76),
        'Icon-App-76x76@2x.png': (152, 152),
        'Icon-App-83.5x83.5@2x.png': (167, 167),
    }
    for filename, size in ios_targets.items():
        path = os.path.join(ios_dir, filename)
        resized = create_rounded_icon(base_img, size, radius_ratio=0.0, padding_ratio=0.10)
        resized.save(path, 'PNG')
        print(f"Berhasil membuat iOS icon: {path} {size}")

    # =========================================================================
    # 5. macOS App Icons
    # =========================================================================
    macos_dir = os.path.join('macos', 'Runner', 'Assets.xcassets', 'AppIcon.appiconset')
    macos_targets = {
        'app_icon_16.png': (16, 16),
        'app_icon_32.png': (32, 32),
        'app_icon_64.png': (64, 64),
        'app_icon_128.png': (128, 128),
        'app_icon_256.png': (256, 256),
        'app_icon_512.png': (512, 512),
        'app_icon_1024.png': (1024, 1024),
    }
    for filename, size in macos_targets.items():
        path = os.path.join(macos_dir, filename)
        resized = create_rounded_icon(base_img, size, radius_ratio=0.22, padding_ratio=0.10)
        resized.save(path, 'PNG')
        print(f"Berhasil membuat macOS icon: {path} {size}")

    print("\n[OK] Seluruh icon SatSet (Windows, Android Adaptive, Web, iOS, macOS) berhasil diperbarui!")

if __name__ == '__main__':
    generate_icons()
