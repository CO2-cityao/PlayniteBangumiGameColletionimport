import requests
import json


def fetch_user_games(username, access_token=None, output_file="games.json"):
    """
    获取指定用户的所有收藏游戏（含评分和评价），保存到txt文件
    :param username: 用户名 或 ID
    :param access_token: 用户授权token（如果只获取公开收藏，可以不传）
    :param output_file: 输出文件名
    """
    url = f"https://api.bgm.tv/v0/users/{username}/collections"
    params = {
        "subject_type": 4,  # 游戏
        "limit": 30,  # 每页最大30条
        "offset": 0
    }

    headers = {
        "User-Agent": "yourname/my-bgm-script/1.0 (https://github.com/yourname/my-bgm-script)",
        "Authorization": f"Bearer {access_token}"  # 如果不需要token可以去掉这一行
    }

    all_games = []
    while True:
        resp = requests.get(url, params=params, headers=headers)
        resp.raise_for_status()
        data = resp.json()

        collections = data.get("data", [])
        if not collections:
            break

        for item in collections:
            subject = item.get("subject", {})
            name = subject.get("name")  # 日文原名
            score = item.get("rate")  # 用户评分
            updated_at = item.get("updated_at")  # 添加时间
            tags = item.get("tags", [])  # 收藏 tag 列表
            comment = item.get("comment")  # 用户短评

            game_info = {
                "name": name,
                "score": score,
                "updated_at": updated_at,
                "tags": tags,
                "comment": comment
            }
            all_games.append(game_info)

        params["offset"] += params["limit"]

        if params["offset"] >= data.get("total", 0):
            break

    # 保存为 JSON 文件
    with open(output_file, "w", encoding="utf-8") as f:
        json.dump(all_games, f, ensure_ascii=False, indent=2)

    print(f"✅ 共获取 {len(all_games)} 个游戏，已保存到 {output_file}")
# 使用示例
if __name__ == "__main__":
    username = ""  # 替换成目标用户的用户ID
    access_token = ""  # 如果要获取自己私有的收藏，需要填写 access_token
    fetch_user_games(username, access_token)
