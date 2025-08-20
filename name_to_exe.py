import os
import json

# 读取 game.json
with open("games.json", "r", encoding="utf-8") as f:
    games = json.load(f)

# 指定输出文件夹
output_dir = r"ExeFiles"  # 修改成你想要保存的路径
os.makedirs(output_dir, exist_ok=True)

for game in games:
    name = game["name"]
    # 去掉非法文件名字符（Windows下不允许的）
    safe_name = "".join(c for c in name if c not in r'\/:*?"<>|')

    # 创建以 name 命名的文件夹
    game_dir = os.path.join(output_dir, safe_name)
    os.makedirs(game_dir, exist_ok=True)

    # 在文件夹里创建 name.exe
    exe_path = os.path.join(game_dir, f"{safe_name}.exe")
    with open(exe_path, "wb") as f:
        pass

    print(f"已创建: {exe_path}")
