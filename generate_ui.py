#!/usr/bin/env python3
"""Generate UI mockup images for LightCalorie app"""

from PIL import Image, ImageDraw, ImageFont
import os

# Colors
ORANGE = (255, 107, 53)
TEAL = (78, 205, 196)
YELLOW = (255, 230, 109)
BG = (250, 250, 250)
DARK_TEXT = (45, 52, 54)
LIGHT_TEXT = (99, 110, 114)
GREEN = (0, 184, 148)
RED = (225, 112, 85)
WHITE = (255, 255, 255)
CARD_BG = (255, 255, 255)
GRAY = (200, 200, 200)

WIDTH = 390
HEIGHT = 844
SCALE = 1

def load_font(size, bold=False):
    """Try to load a system font, fall back to default"""
    try:
        if bold:
            return ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", size)
        else:
            return ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", size)
    except:
        return ImageFont.load_default()

def draw_card(draw, x, y, w, h, radius=16):
    """Draw a rounded rectangle card"""
    draw.rounded_rectangle([x, y, x+w, y+h], radius=radius, fill=CARD_BG, outline=(230, 230, 230), width=1)

def draw_progress_bar(draw, x, y, w, h, progress, color, bg_color=GRAY):
    """Draw a progress bar"""
    draw.rounded_rectangle([x, y, x+w, y+h], radius=h//2, fill=bg_color)
    fill_w = int(w * min(progress, 1.0))
    if fill_w > 0:
        draw.rounded_rectangle([x, y, x+fill_w, y+h], radius=h//2, fill=color)

def create_homepage():
    """Generate home page mockup"""
    img = Image.new('RGB', (WIDTH, HEIGHT), BG)
    draw = ImageDraw.Draw(img)

    font_title = load_font(20, bold=True)
    font_normal = load_font(14)
    font_small = load_font(12)
    font_big = load_font(32, bold=True)
    font_medium = load_font(16, bold=True)

    # Header
    draw.rectangle([0, 0, WIDTH, 60], fill=ORANGE)
    draw.text((20, 20), "轻卡", fill=WHITE, font=font_title)
    draw.text((WIDTH-60, 20), "⚙️", fill=WHITE, font=font_normal)

    y = 80

    # Card 1: Check-in Progress
    draw_card(draw, 15, y, WIDTH-30, 120)
    draw.text((30, y+15), "📊 今日打卡进度", fill=DARK_TEXT, font=font_medium)
    draw_progress_bar(draw, 30, y+45, WIDTH-60, 16, 0.6, TEAL)
    draw.text((30, y+70), "3/5", fill=DARK_TEXT, font=font_normal)
    draw.text((30, y+90), "✅ 早餐  ✅ 午餐  ⏳ 晚餐  ⏳ 饮水  🔴 运动", fill=LIGHT_TEXT, font=font_small)

    y += 140

    # Card 2: Weight Trend
    draw_card(draw, 15, y, WIDTH-30, 150)
    draw.text((30, y+15), "📈 体重趋势", fill=DARK_TEXT, font=font_medium)
    draw.text((30, y+40), "📉 当前: 72.5kg", fill=DARK_TEXT, font=font_normal)
    # Simple chart
    chart_x, chart_y = 30, y+70
    chart_w, chart_h = WIDTH-60, 50
    draw.rectangle([chart_x, chart_y, chart_x+chart_w, chart_y+chart_h], outline=(230,230,230))
    # Draw trend line
    points = [(chart_x+10, chart_y+40), (chart_x+60, chart_y+35), (chart_x+110, chart_y+30),
              (chart_x+160, chart_y+25), (chart_x+210, chart_y+20), (chart_x+260, chart_y+15)]
    for i in range(len(points)-1):
        draw.line([points[i], points[i+1]], fill=TEAL, width=2)
    draw.text((30, y+130), "本周累计下降: 0.8kg", fill=GREEN, font=font_small)

    y += 170

    # Card 3: Calories
    draw_card(draw, 15, y, WIDTH-30, 130)
    draw.text((30, y+15), "🔥 今日摄入", fill=DARK_TEXT, font=font_medium)
    draw.text((30, y+45), "1,285 / 1,800 大卡", fill=DARK_TEXT, font=font_big)
    draw_progress_bar(draw, 30, y+85, WIDTH-60, 16, 0.71, ORANGE)
    draw.text((30, y+110), "碳水 320g    蛋白 85g    脂肪 45g", fill=LIGHT_TEXT, font=font_small)

    y += 150

    # Card 4: Goals
    draw_card(draw, 15, y, WIDTH-30, 100)
    draw.text((30, y+15), "🎯 本周目标", fill=DARK_TEXT, font=font_medium)
    draw.text((30, y+45), "· 减重1kg", fill=LIGHT_TEXT, font=font_small)
    draw.text((30, y+62), "· 打卡5天", fill=LIGHT_TEXT, font=font_small)
    draw.text((30, y+79), "· 不吃夜宵", fill=LIGHT_TEXT, font=font_small)

    # Bottom Nav
    nav_y = HEIGHT - 80
    draw.rectangle([0, nav_y, WIDTH, HEIGHT], fill=WHITE, outline=(230,230,230))
    nav_items = ["🏠 首页", "📝 记录", "📅 打卡", "👤 我的"]
    for i, item in enumerate(nav_items):
        x = 20 + i * (WIDTH // 4)
        color = ORANGE if i == 0 else LIGHT_TEXT
        draw.text((x, nav_y + 20), item, fill=color, font=font_small)

    return img

def create_record_page():
    """Generate food record page mockup"""
    img = Image.new('RGB', (WIDTH, HEIGHT), BG)
    draw = ImageDraw.Draw(img)

    font_title = load_font(20, bold=True)
    font_normal = load_font(14)
    font_small = load_font(12)
    font_medium = load_font(16, bold=True)

    # Header
    draw.rectangle([0, 0, WIDTH, 60], fill=TEAL)
    draw.text((20, 20), "饮食记录", fill=WHITE, font=font_title)
    draw.text((WIDTH-50, 20), "+ 添加", fill=WHITE, font=font_normal)

    y = 70

    # Date header
    draw.text((20, y+10), "< 3月24日 周二 >", fill=DARK_TEXT, font=font_medium)
    draw.text((WIDTH-80, y+10), "总计 ▶", fill=LIGHT_TEXT, font=font_small)

    y += 50

    # Breakfast
    draw.text((20, y), "🍳 早餐  08:30", fill=DARK_TEXT, font=font_medium)
    y += 25
    draw_card(draw, 15, y, WIDTH-30, 90)
    draw.text((30, y+10), "全麦面包 2片    150g    180kcal", fill=LIGHT_TEXT, font=font_small)
    draw.text((30, y+30), "煮鸡蛋 1个      50g     70kcal", fill=LIGHT_TEXT, font=font_small)
    draw.text((30, y+50), "牛奶 1杯        250ml   130kcal", fill=LIGHT_TEXT, font=font_small)
    draw.text((WIDTH-100, y+65), "小计: 380kcal", fill=ORANGE, font=font_small)

    y += 105

    # Lunch
    draw.text((20, y), "🍱 午餐  12:30", fill=DARK_TEXT, font=font_medium)
    y += 25
    draw_card(draw, 15, y, WIDTH-30, 70)
    draw.text((30, y+10), "糙米饭 1碗      200g    220kcal", fill=LIGHT_TEXT, font=font_small)
    draw.text((30, y+30), "西兰花炒肉    150g    180kcal", fill=LIGHT_TEXT, font=font_small)
    draw.text((WIDTH-100, y+45), "小计: 400kcal", fill=ORANGE, font=font_small)

    y += 85

    # Dinner (empty)
    draw.text((20, y), "🍜 晚餐  18:30", fill=DARK_TEXT, font=font_medium)
    y += 25
    draw_card(draw, 15, y, WIDTH-30, 40)
    draw.text((30, y+10), "点击添加晚餐记录...", fill=GRAY, font=font_small)

    y += 60

    # Summary
    draw.rectangle([10, y, WIDTH-10, y+30], fill=(255, 240, 230))
    draw.text((WIDTH//2 - 80, y+5), "今日总摄入: 780 / 1,800 kcal", fill=ORANGE, font=font_normal)

    y += 50

    # Quick actions
    draw.text((20, y), "📱 快速打卡", fill=DARK_TEXT, font=font_medium)
    y += 30
    quick_items = [("🍎", "水果"), ("🥛", "牛奶"), ("💧", "喝水"), ("🏃", "运动")]
    for i, (emoji, label) in enumerate(quick_items):
        x = 20 + i * 90
        draw_card(draw, x, y, 75, 60, radius=12)
        draw.text((x+20, y+10), emoji, fill=DARK_TEXT, font=load_font(24))
        draw.text((x+12, y+40), label, fill=LIGHT_TEXT, font=font_small)

    # Bottom Nav
    nav_y = HEIGHT - 80
    draw.rectangle([0, nav_y, WIDTH, HEIGHT], fill=WHITE, outline=(230,230,230))
    nav_items = ["🏠 首页", "📝 记录", "📅 打卡", "👤 我的"]
    for i, item in enumerate(nav_items):
        x = 20 + i * (WIDTH // 4)
        color = TEAL if i == 1 else LIGHT_TEXT
        draw.text((x, nav_y + 20), item, fill=color, font=font_small)

    return img

def create_checkin_page():
    """Generate check-in calendar page mockup"""
    img = Image.new('RGB', (WIDTH, HEIGHT), BG)
    draw = ImageDraw.Draw(img)

    font_title = load_font(20, bold=True)
    font_normal = load_font(14)
    font_small = load_font(12)
    font_medium = load_font(16, bold=True)
    font_big = load_font(28, bold=True)

    # Header
    draw.rectangle([0, 0, WIDTH, 60], fill=YELLOW)
    draw.text((20, 20), "打卡日历", fill=DARK_TEXT, font=font_title)
    draw.text((WIDTH-80, 20), "3月 2026 >", fill=DARK_TEXT, font=font_normal)

    y = 70

    # Calendar
    draw_card(draw, 15, y, WIDTH-30, 180)
    draw.text((30, y+10), "日   一   二   三   四   五   六", fill=LIGHT_TEXT, font=font_small)
    y += 35
    weeks = [
        ["", "", "1", "2", "3", "4", "5"],
        ["6", "7", "8", "9", "10", "11", "12"],
        ["13", "14", "15", "16", "17", "18", "19"],
        ["20", "21", "22", "23", "24", "25", "26"],
        ["27", "28", "29", "30", "31", "", ""],
    ]
    colors = [LIGHT_TEXT, LIGHT_TEXT, ORANGE, ORANGE, ORANGE, RED, GRAY]
    for row_idx, week in enumerate(weeks):
        for col_idx, day in enumerate(week):
            x = 30 + col_idx * 45
            dy = y + row_idx * 28
            if day == "24":
                draw.ellipse([x-10, dy-2, x+10, dy+18], fill=ORANGE)
                draw.text((x-5, dy), "24", fill=WHITE, font=font_small)
            elif day and int(day) < 24:
                draw.text((x-3, dy), day, fill=GREEN, font=font_small)
            elif day:
                draw.text((x-3, dy), day, fill=LIGHT_TEXT, font=font_small)

    y += 150
    draw.text((30, y), "🔴 断签  ✅ 打卡  ⬜ 未到  🎉 今日", fill=LIGHT_TEXT, font=font_small)

    y += 40

    # Streak card
    draw_card(draw, 15, y, WIDTH-30, 90)
    draw.text((30, y+15), "🏆 连续打卡 12 天", fill=ORANGE, font=font_big)
    draw.text((30, y+50), "★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★", fill=YELLOW, font=font_medium)
    draw.text((30, y+70), "历史最佳: 28天", fill=LIGHT_TEXT, font=font_small)

    y += 110

    # Today's tasks
    draw_card(draw, 15, y, WIDTH-30, 160)
    draw.text((30, y+15), "📋 今日打卡任务", fill=DARK_TEXT, font=font_medium)
    tasks = ["[✓] 早餐记录", "[✓] 午餐记录", "[ ] 晚餐记录", "[ ] 体重记录", "[ ] 喝8杯水  0/8", "[ ] 运动30分钟"]
    for i, task in enumerate(tasks):
        color = GREEN if task.startswith("[✓]") else LIGHT_TEXT
        draw.text((30, y+40+i*18), task, fill=color, font=font_small)

    y += 175

    # Photo check-in button
    draw_card(draw, 15, y, WIDTH-30, 50, radius=12)
    draw.rectangle([30, y+10, 50, y+30], fill=ORANGE)
    draw.text((60, y+12), "📷 拍照打卡", fill=ORANGE, font=font_medium)

    # Bottom Nav
    nav_y = HEIGHT - 80
    draw.rectangle([0, nav_y, WIDTH, HEIGHT], fill=WHITE, outline=(230,230,230))
    nav_items = ["🏠 首页", "📝 记录", "📅 打卡", "👤 我的"]
    for i, item in enumerate(nav_items):
        x = 20 + i * (WIDTH // 4)
        color = YELLOW if i == 2 else LIGHT_TEXT
        draw.text((x, nav_y + 20), item, fill=color, font=font_small)

    return img

def create_profile_page():
    """Generate profile page mockup"""
    img = Image.new('RGB', (WIDTH, HEIGHT), BG)
    draw = ImageDraw.Draw(img)

    font_title = load_font(20, bold=True)
    font_normal = load_font(14)
    font_small = load_font(12)
    font_medium = load_font(16, bold=True)
    font_big = load_font(24, bold=True)

    y = 30

    # Avatar
    draw.ellipse([WIDTH//2 - 40, y, WIDTH//2 + 40, y+80], fill=GRAY)
    draw.text((WIDTH//2 - 25, y+25), "👤", fill=WHITE, font=load_font(32))
    y += 95

    draw.text((WIDTH//2 - 60, y), "减脂中的张三大王", fill=DARK_TEXT, font=font_medium)
    y += 25
    draw.text((WIDTH//2 - 40, y), "已坚持 45 天", fill=ORANGE, font=font_normal)
    y += 40

    # Weight stats
    draw_card(draw, 15, y, WIDTH-30, 120)
    draw.text((30, y+15), "📊 我的数据", fill=DARK_TEXT, font=font_medium)
    draw.text((30, y+40), "初始体重      78.5kg", fill=LIGHT_TEXT, font=font_small)
    draw.text((30, y+60), "当前体重      72.5kg  ↓6.0", fill=DARK_TEXT, font=font_small)
    draw.text((30, y+80), "目标体重      65.0kg", fill=LIGHT_TEXT, font=font_small)
    draw_progress_bar(draw, 30, y+100, WIDTH-60, 8, 0.8, GREEN)
    draw.text((WIDTH-80, y+90), "80%", fill=GREEN, font=font_small)

    y += 140

    # Check-in stats
    draw_card(draw, 15, y, WIDTH-30, 100)
    draw.text((30, y+15), "📅 打卡数据", fill=DARK_TEXT, font=font_medium)
    draw.text((30, y+40), "本月打卡      18/31 天", fill=LIGHT_TEXT, font=font_small)
    draw.text((30, y+60), "连续打卡      12 天 🏆", fill=ORANGE, font=font_small)
    draw.text((30, y+80), "累计打卡      45 天", fill=LIGHT_TEXT, font=font_small)

    y += 120

    # Food stats
    draw_card(draw, 15, y, WIDTH-30, 80)
    draw.text((30, y+15), "🍔 饮食数据", fill=DARK_TEXT, font=font_medium)
    draw.text((30, y+40), "本月平均摄入  1,650 大卡", fill=LIGHT_TEXT, font=font_small)
    draw.text((30, y+60), "达标天数      22/26 天", fill=GREEN, font=font_small)

    y += 100

    # Settings
    draw_card(draw, 15, y, WIDTH-30, 180)
    draw.text((30, y+15), "⚙️ 设置", fill=DARK_TEXT, font=font_medium)
    settings = ["👤 个人资料", "🎯 目标设置", "🔔 提醒设置", "📊 数据统计", "📱 账号绑定", "❓ 帮助反馈"]
    for i, item in enumerate(settings):
        draw.text((30, y+40+i*22), item, fill=DARK_TEXT, font=font_small)
        draw.text((WIDTH-50, y+40+i*22), ">", fill=LIGHT_TEXT, font=font_small)

    # Bottom Nav
    nav_y = HEIGHT - 80
    draw.rectangle([0, nav_y, WIDTH, HEIGHT], fill=WHITE, outline=(230,230,230))
    nav_items = ["🏠 首页", "📝 记录", "📅 打卡", "👤 我的"]
    for i, item in enumerate(nav_items):
        x = 20 + i * (WIDTH // 4)
        color = TEAL if i == 3 else LIGHT_TEXT
        draw.text((x, nav_y + 20), item, fill=color, font=font_small)

    return img

def create_login_page():
    """Generate login page mockup"""
    img = Image.new('RGB', (WIDTH, HEIGHT), WHITE)
    draw = ImageDraw.Draw(img)

    font_title = load_font(24, bold=True)
    font_normal = load_font(14)
    font_small = load_font(12)
    font_medium = load_font(16, bold=True)
    font_big = load_font(32, bold=True)

    y = 120

    draw.text((WIDTH//2 - 80, y), "✨ 欢迎使用 轻卡", fill=ORANGE, font=font_title)

    y += 80

    # WeChat login
    draw_card(draw, 30, y, WIDTH-60, 50, radius=12)
    draw.text((WIDTH//2 - 50, y+15), "📱  微信一键登录", fill=WHITE, font=font_medium)
    y += 70

    draw.text((WIDTH//2 - 60, y), "────────── 或 ──────────", fill=GRAY, font=font_normal)

    y += 50

    # Email login
    draw_card(draw, 30, y, WIDTH-60, 50, radius=12)
    draw.text((WIDTH//2 - 60, y+15), "📧  邮箱注册/登录", fill=ORANGE, font=font_medium)
    y += 70

    draw.text((WIDTH//2 - 60, y), "────────── 或 ──────────", fill=GRAY, font=font_normal)

    y += 50

    # Phone login
    draw_card(draw, 30, y, WIDTH-60, 50, radius=12)
    draw.text((WIDTH//2 - 50, y+15), "📞  手机号登录", fill=TEAL, font=font_medium)

    y += 100

    draw.text((WIDTH//2 - 120, y), "登录即表示同意《用户协议》和《隐私政策》", fill=LIGHT_TEXT, font=font_small)

    return img


# Generate all pages
output_dir = "/Users/zhangbaigei/.openclaw/workspace/light_calorie/ui_mockups"
os.makedirs(output_dir, exist_ok=True)

pages = [
    ("01_home.png", create_homepage),
    ("02_record.png", create_record_page),
    ("03_checkin.png", create_checkin_page),
    ("04_profile.png", create_profile_page),
    ("05_login.png", create_login_page),
]

for filename, creator in pages:
    img = creator()
    img.save(os.path.join(output_dir, filename))
    print(f"Generated: {filename}")

print("\nAll UI mockups generated!")
