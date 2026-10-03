"""Google Play feature graphic (1024x500): splash gradient, V mark, name and tagline.
Run from the project root: python3 assets/store/make_feature_graphic.py"""
from PIL import Image, ImageDraw, ImageFont
import numpy as np, math

W, H, SS = 1024, 500, 3
GRAD = [(0, (0x12, 0x56, 0x4C)), (0.45, (0x0F, 0x4A, 0x41)), (1, (0x0A, 0x2C, 0x28))]

def background(w, h):
    ys, xs = np.mgrid[0:h, 0:w].astype(float)
    x = xs / (w - 1) * 2 - 1; y = ys / (h - 1) * 2 - 1
    bx, by, ex, ey = -0.4, -1, 0.4, 1; dx, dy = ex - bx, ey - by
    t = np.clip(((x - bx) * dx + (y - by) * dy) / (dx * dx + dy * dy), 0, 1)
    img = np.zeros((h, w, 3))
    for (t0, c0), (t1, c1) in zip(GRAD, GRAD[1:]):
        m = (t >= t0) & (t <= t1); f = ((t - t0) / (t1 - t0))[..., None]
        img = np.where(m[..., None], np.array(c0) * (1 - f) + np.array(c1) * f, img)
    for cx, cy, r, a in [(w * 0.12, h * 0.05, w * 0.45, 0.32), (w * 0.95, h * 1.05, w * 0.35, 0.18)]:
        d = np.sqrt((xs - cx) ** 2 + (ys - cy) ** 2) / r
        k = (np.clip(1 - d, 0, 1) ** 2 * a)[..., None]
        img = img * (1 - k) + np.array([0x37, 0xB1, 0x99]) * k
    return Image.fromarray(img.astype('uint8')).convert('RGBA')

def rings(img, cx, cy):
    layer = Image.new('RGBA', img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    for r in (110, 170, 230):
        d.ellipse([cx - r * SS, cy - r * SS, cx + r * SS, cy + r * SS], outline=(255, 255, 255, 26), width=3 * SS)
    img.alpha_composite(layer)

def capsule(size, p_top, p_bot, radius, top_y):
    m = Image.new('L', size, 0); d = ImageDraw.Draw(m)
    (x0, y0), (x1, y1) = p_top, p_bot
    ang = math.atan2(y1 - y0, x1 - x0); nx, ny = -math.sin(ang) * radius, math.cos(ang) * radius
    ux, uy = math.cos(ang), math.sin(ang); xa, ya = x0 - ux * radius * 4, y0 - uy * radius * 4
    d.polygon([(xa + nx, ya + ny), (x1 + nx, y1 + ny), (x1 - nx, y1 - ny), (xa - nx, ya - ny)], fill=255)
    d.ellipse([x1 - radius, y1 - radius, x1 + radius, y1 + radius], fill=255)
    d.rectangle([0, 0, size[0], top_y], fill=0)
    return np.asarray(m) / 255.0

def v_mark(size, cx, cy, width):
    """Brand V: white left stroke, teal right stroke (as on the splash logo)."""
    mw, mh = 133, 92; cx0, cy0 = 4 + mw / 2, 24 + mh / 2; sc = width / mw
    P = lambda x, y: ((x - cx0) * sc + cx, (y - cy0) * sc + cy); top = P(0, 24)[1]
    teal = capsule(size, P(116, 24), P(68, 99), 16.9 * sc, top)
    white = capsule(size, P(22, 24), P(51, 76), 15.5 * sc, top)
    ys = np.arange(size[1])[:, None] * np.ones((1, size[0]))
    t = np.clip((ys - top) / (92 * sc), 0, 1)[..., None]
    tc = np.array([0x1F, 0xC2, 0xBE]) * (1 - t) + np.array([0x0B, 0x7A, 0x80]) * t
    rgb = tc * teal[..., None]; rgb = rgb * (1 - white[..., None]) + 255 * white[..., None]
    a = np.maximum(teal, white)
    rgb = np.where(a[..., None] > 0, rgb / np.maximum(a, 1e-6)[..., None], 0)
    out = np.zeros((size[1], size[0], 4)); out[..., :3] = rgb; out[..., 3] = a * 255
    return Image.fromarray(out.astype('uint8'))

w, h = W * SS, H * SS
img = background(w, h)
rings(img, int(w * 0.97), int(h * 0.02))
img.alpha_composite(v_mark((w, h), w * 0.2, h * 0.5, w * 0.23))

d = ImageDraw.Draw(img)
title = ImageFont.truetype('assets/fonts/BricolageGrotesque-700.ttf', 80 * SS)
tag = ImageFont.truetype('assets/fonts/HankenGrotesk-600.ttf', 30 * SS)
small = ImageFont.truetype('assets/fonts/HankenGrotesk-500.ttf', 22 * SS)
x = int(w * 0.40)
d.text((x, int(h * 0.29)), 'Velora Cares', font=title, fill=(255, 255, 255))
d.text((x + 4 * SS, int(h * 0.52)), 'Clock in. Check in. Get paid.', font=tag, fill=(0xE0, 0xA7, 0x2E))
d.text((x + 4 * SS, int(h * 0.64)), 'The app for home care caregivers', font=small, fill=(0xCF, 0xE2, 0xDC))

img.resize((W, H), Image.LANCZOS).convert('RGB').save('assets/store/feature_graphic.png', optimize=True)
print('ok')
