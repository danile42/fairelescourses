#!/usr/bin/env python3
"""Generate a 1024x1024 market-stand PNG icon using only Python stdlib."""
import struct, zlib, math

SIZE = 1024

def clamp(v): return max(0, min(255, int(v)))

# RGBA pixel buffer
pixels = bytearray(SIZE * SIZE * 4)

def px(x, y, r, g, b, a=255):
    if 0 <= x < SIZE and 0 <= y < SIZE:
        i = (y * SIZE + x) * 4
        # alpha blend onto existing
        ea = pixels[i+3]
        fa = a / 255
        if ea == 0:
            pixels[i], pixels[i+1], pixels[i+2], pixels[i+3] = clamp(r), clamp(g), clamp(b), a
        else:
            pixels[i]   = clamp(pixels[i]   * (1-fa) + r * fa)
            pixels[i+1] = clamp(pixels[i+1] * (1-fa) + g * fa)
            pixels[i+2] = clamp(pixels[i+2] * (1-fa) + b * fa)
            pixels[i+3] = min(255, ea + a)

def fill_rect(x1,y1,x2,y2,r,g,b,a=255):
    for y in range(y1,y2):
        for x in range(x1,x2):
            px(x,y,r,g,b,a)

def fill_circle(cx,cy,rad,r,g,b,a=255):
    for y in range(cy-rad, cy+rad+1):
        for x in range(cx-rad, cx+rad+1):
            if (x-cx)**2+(y-cy)**2 <= rad**2:
                px(x,y,r,g,b,a)

def fill_circle_aa(cx,cy,rad,r,g,b):
    for y in range(cy-rad-1, cy+rad+2):
        for x in range(cx-rad-1, cx+rad+2):
            d = math.sqrt((x-cx)**2+(y-cy)**2)
            a = clamp(255*(1-(d-rad+0.5)))
            if a > 0:
                px(x,y,r,g,b,a)

def fill_ellipse(cx,cy,rx,ry,r,g,b,a=255):
    for y in range(cy-ry, cy+ry+1):
        for x in range(cx-rx, cx+rx+1):
            if (x-cx)**2/rx**2+(y-cy)**2/ry**2 <= 1:
                px(x,y,r,g,b,a)

def fill_polygon(pts, r,g,b,a=255):
    ys = [p[1] for p in pts]
    miny,maxy = max(0,min(ys)), min(SIZE-1,max(ys))
    for y in range(miny,maxy+1):
        xs = []
        n = len(pts)
        for i in range(n):
            x1,y1 = pts[i]; x2,y2 = pts[(i+1)%n]
            if (y1<=y<y2) or (y2<=y<y1):
                t = (y-y1)/(y2-y1)
                xs.append(int(x1+t*(x2-x1)))
        xs.sort()
        for i in range(0,len(xs)-1,2):
            for x in range(xs[i],xs[i+1]+1):
                px(x,y,r,g,b,a)

# ── Background (light green circle) ─────────────────────────────────────────
fill_circle(512,512,512, 200,230,201)

# ── Scale factor (design was 1024-based) ────────────────────────────────────
S = SIZE/1024

def s(v): return int(v*S)

# ── Back wall ────────────────────────────────────────────────────────────────
fill_rect(s(160),s(340),s(864),s(760), 161,136,127)   # brown
fill_rect(s(180),s(360),s(844),s(740), 178,157,148)   # lighter

# ── Striped awning (trapezoid with alternating red/yellow stripes) ───────────
STRIPE_W = s(75)
AWNING_TOP_Y = s(200)
AWNING_BOT_Y = s(360)
AWNING_LEFT_TOP  = s(120)
AWNING_RIGHT_TOP = s(904)
AWNING_LEFT_BOT  = s(64)
AWNING_RIGHT_BOT = s(960)

colors_stripe = [(229,57,53), (255,249,196)]  # red / light yellow
for i, sx in enumerate(range(AWNING_LEFT_BOT, AWNING_RIGHT_BOT, STRIPE_W)):
    cr,cg,cb = colors_stripe[i % 2]
    fill_polygon([
        (sx, AWNING_BOT_Y),
        (sx+STRIPE_W, AWNING_BOT_Y),
        (AWNING_LEFT_TOP + int((sx+STRIPE_W-AWNING_LEFT_BOT)/(AWNING_RIGHT_BOT-AWNING_LEFT_BOT)*(AWNING_RIGHT_TOP-AWNING_LEFT_TOP)), AWNING_TOP_Y),
        (AWNING_LEFT_TOP + int((sx-AWNING_LEFT_BOT)/(AWNING_RIGHT_BOT-AWNING_LEFT_BOT)*(AWNING_RIGHT_TOP-AWNING_LEFT_TOP)), AWNING_TOP_Y),
    ], cr,cg,cb)

# Awning outline
for t in range(4):
    fill_polygon([
        (s(120)-t,s(200)-t),(s(904)+t,s(200)-t),(s(960)+t,s(360)+t),(s(64)-t,s(360)+t)
    ], 183,28,28, 80)

# Scalloped edge
SCALLOP_R = s(32)
for i, cx in enumerate(range(s(96), s(960), s(64))):
    cr,cg,cb = colors_stripe[i%2]
    fill_circle_aa(cx, s(375), SCALLOP_R, cr,cg,cb)

# ── Counter ───────────────────────────────────────────────────────────────────
fill_rect(s(140),s(555),s(884),s(595), 93,64,55)   # dark edge
fill_rect(s(160),s(480),s(864),s(560), 121,85,72)  # table surface

# ── Support poles ─────────────────────────────────────────────────────────────
fill_rect(s(180),s(360),s(204),s(800), 109,76,65)
fill_rect(s(820),s(360),s(844),s(800), 109,76,65)

# ── Produce ───────────────────────────────────────────────────────────────────
# Green cabbage / lettuce (left)
fill_ellipse(s(240),s(510),s(55),s(45), 46,125,50)
fill_ellipse(s(240),s(496),s(44),s(34), 56,142,60)
fill_ellipse(s(225),s(506),s(27),s(21), 67,160,71)
fill_ellipse(s(255),s(501),s(27),s(21), 67,160,71)

# Tomatoes (center-left)
fill_circle_aa(s(360),s(506),s(31), 230,74,25)
fill_circle_aa(s(406),s(511),s(27), 244,81,30)
fill_circle_aa(s(340),s(521),s(23), 191,54,12)

# Bananas (center) — drawn as a curved yellow arc
for angle_deg in range(-30, 50, 2):
    ang = math.radians(angle_deg)
    cx = s(510) + int(s(50)*math.cos(ang))
    cy = s(510) - int(s(60)*math.sin(ang))
    fill_circle(cx, cy, s(14), 249,168,37)
for angle_deg in range(-25, 45, 2):
    ang = math.radians(angle_deg)
    cx = s(510) + int(s(50)*math.cos(ang))
    cy = s(510) - int(s(60)*math.sin(ang))
    fill_circle(cx, cy, s(8), 245,127,23)

# Grapes (right-center)
grape_positions = [(s(630),s(500)),(s(660),s(493)),(s(648),s(520)),
                   (s(625),s(522)),(s(672),s(516)),(s(638),s(540)),
                   (s(662),s(538))]
for gx,gy in grape_positions:
    fill_circle_aa(gx,gy,s(19), 106,27,154)
for gx,gy in grape_positions:
    fill_circle_aa(gx,gy,s(14), 142,36,170)

# Red apples (right)
fill_circle_aa(s(758),s(508),s(31), 198,40,40)
fill_circle_aa(s(798),s(515),s(27), 211,47,47)
# apple stem
fill_rect(s(756),s(472),s(763),s(482), 46,125,50)

# ── Sign banner ───────────────────────────────────────────────────────────────
fill_rect(s(255),s(388),s(769),s(463), 255,248,225)
for t in range(s(5)):
    for y in range(s(388)+t, s(463)-t):
        for x in [s(255)+t, s(769)-t]:
            px(x,y,249,168,37)
    for x in range(s(255)+t, s(769)-t):
        for yy in [s(388)+t, s(463)-t]:
            px(x,yy,249,168,37)

# ── Write PNG ─────────────────────────────────────────────────────────────────
def write_png(path, w, h, data):
    def chunk(tag, payload):
        c = struct.pack('>I',len(payload)) + tag + payload
        return c + struct.pack('>I', zlib.crc32(tag+payload)&0xffffffff)
    raw = b''
    for y in range(h):
        row = bytes([0])  # filter none
        row += bytes(data[y*w*4:(y+1)*w*4])
        raw += row
    compressed = zlib.compress(raw, 9)
    png  = b'\x89PNG\r\n\x1a\n'
    png += chunk(b'IHDR', struct.pack('>IIBBBBB', w, h, 8, 6, 0, 0, 0))
    png += chunk(b'IDAT', compressed)
    png += chunk(b'IEND', b'')
    with open(path, 'wb') as f:
        f.write(png)

write_png('/Users/daniel/dev/fairelescourses/assets/icon.png', SIZE, SIZE, pixels)
print("icon.png written")
