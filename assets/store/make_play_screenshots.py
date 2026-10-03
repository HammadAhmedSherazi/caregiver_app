"""Google Play screenshots: each app screenshot is placed whole (never cropped)
on a 9:16 canvas with the splash gradient and a caption.
Usage: python3 assets/store/make_play_screenshots.py <src_dir> <out_dir>"""
import sys, os
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import numpy as np

SRC, OUT = sys.argv[1], sys.argv[2]
GRAD = [(0, (0x12, 0x56, 0x4C)), (0.45, (0x0F, 0x4A, 0x41)), (1, (0x0A, 0x2C, 0x28))]
FONT = 'assets/fonts/BricolageGrotesque-700.ttf'
SUB = 'assets/fonts/HankenGrotesk-500.ttf'

PHONE = [  # iPhone 1284x2778
    ('14', 'Sign in with Face ID', 'or your phone number'),
    ('16', 'Your day at a glance', 'Visits, this week and next payday'),
    ('17', 'Track your time', 'Every visit, week by week'),
    ('18', 'Monthly check-in', 'Sign in about a minute'),
    ('19', 'See your pay', 'Paystubs and how pay works'),
    ('21', 'Your profile', 'Contact details and hours by week'),
    ('22', 'Your clients', 'Everyone assigned to you'),
    ('24', 'Help when you need it', 'Quick answers and the office'),
]
TABLET = [  # iPad 2064x2752
    ('3', 'Your day at a glance', 'Visits, this week and next payday'),
    ('4', 'Track your time', 'Every visit, week by week'),
    ('5', 'Monthly check-in', 'Sign in about a minute'),
    ('6', 'See your pay', 'Paystubs and how pay works'),
    ('8', 'Your profile', 'Contact details and hours by week'),
    ('9', 'Your clients', 'Everyone assigned to you'),
    ('12', 'Help when you need it', 'Quick answers and the office'),
]

def background(w, h):
    ys, xs = np.mgrid[0:h, 0:w].astype(np.float32)
    x = xs / (w - 1) * 2 - 1; y = ys / (h - 1) * 2 - 1
    bx, by, ex, ey = -0.4, -1, 0.4, 1; dx, dy = ex - bx, ey - by
    t = np.clip(((x - bx) * dx + (y - by) * dy) / (dx * dx + dy * dy), 0, 1)
    img = np.zeros((h, w, 3), np.float32)
    for (t0, c0), (t1, c1) in zip(GRAD, GRAD[1:]):
        m = (t >= t0) & (t <= t1); f = ((t - t0) / (t1 - t0))[..., None]
        img = np.where(m[..., None], np.array(c0) * (1 - f) + np.array(c1) * f, img)
    d = np.sqrt((xs - w * 0.15) ** 2 + (ys - h * 0.02) ** 2) / (w * 0.9)
    k = (np.clip(1 - d, 0, 1) ** 2 * 0.3)[..., None]
    img = img * (1 - k) + np.array([0x37, 0xB1, 0x99]) * k
    return Image.fromarray(img.astype('uint8')).convert('RGBA')

def make(src, title, sub, W, H):
    canvas = background(W, H)
    shot = Image.open(src).convert('RGBA')
    top = int(H * 0.165)            # caption band
    tablet = shot.width / shot.height > 0.6
    margin = int(W * (0.04 if tablet else 0.07))
    box_w, box_h = W - 2 * margin, H - top - int(H * 0.04)
    s = min(box_w / shot.width, box_h / shot.height)   # fit: never crop
    sw, sh = int(shot.width * s), int(shot.height * s)
    shot = shot.resize((sw, sh), Image.LANCZOS)
    # Small radius on tablets so the corners never cut the status bar text.
    r = int(sw * (0.025 if tablet else 0.06))
    mask = Image.new('L', (sw, sh), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, sw - 1, sh - 1], radius=r, fill=255)
    x, y = (W - sw) // 2, top + (box_h - sh) // 2
    shadow = Image.new('RGBA', canvas.size, (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle([x, y + int(H * 0.008), x + sw, y + sh + int(H * 0.008)],
                                             radius=r, fill=(0, 0, 0, 110))
    canvas.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(W * 0.02)))
    canvas.paste(shot, (x, y), mask)
    d = ImageDraw.Draw(canvas)
    tf = ImageFont.truetype(FONT, int(W * 0.068)); sf = ImageFont.truetype(SUB, int(W * 0.036))
    d.text((W / 2, top * 0.42), title, font=tf, fill=(255, 255, 255), anchor='mm')
    d.text((W / 2, top * 0.72), sub, font=sf, fill=(0xE0, 0xA7, 0x2E), anchor='mm')
    return canvas.convert('RGB')

for folder, items, (W, H) in [('phone', PHONE, (1080, 1920)),
                              ('tablet-7in', TABLET, (1440, 2560)),
                              ('tablet-10in', TABLET, (1440, 2560))]:
    os.makedirs(f'{OUT}/{folder}', exist_ok=True)
    for i, (n, title, sub) in enumerate(items, 1):
        make(f'{SRC}/{n}.png', title, sub, W, H).save(f'{OUT}/{folder}/{i:02d}.png', optimize=True)
print('ok')
