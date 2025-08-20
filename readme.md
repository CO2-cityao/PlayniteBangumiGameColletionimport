# Playnite Bangumi Game Colletion import
## 这是什么

[bangumi.tv](https://bgm.tv/) 游戏收藏导入 [Playnite](https://playnite.link/)

由 ChatGPT 编写的，一个半自动化的流程，获取 [bangumi.tv](https://bgm.tv/) 用户所有收藏游戏，并导入 [Playnite](https://playnite.link/) ，同时支持导入评分、
评论、收藏时间。

建议配合 [Playnite Bangumi Metadata Provider](https://github.com/Ivanlon30000/PlayniteBangumiMetadata) 使用。

## 使用前

1. 确保已经安装python环境
2. 在 [个人令牌](https://next.bgm.tv/demo/access-token) 生成一个 Access Token

#### 不设置 Access Token 可能会出现以下情况：  
1. 部分游戏搜索不到；
2. 部分游戏能够搜索到，但获取信息失败。  

> bangumi 账号注册后的一段时间之内是没有访问部分游戏信息的权限的  
> 因此新注册的账号即使配置了 Access Token，也有可能出现搜索不到部分游戏或获取信息失败的情况

## 基本流程
1. 运行 `get_game_from_bgm.py`获取用户游戏收藏
2. 运行 `name_to_exe.py` 批量生成游戏 exe 以便 Playnite 导入
3. 使用 Playnite 导入空白游戏
4. 数据更新：Playnite 运行 `update.ps1` 脚本，导入用户评分、标签、上次游玩、添加日期、备注。
5. 数据更新：(强烈建议) 使用 [Playnite Bangumi Metadata Provider](https://github.com/Ivanlon30000/PlayniteBangumiMetadata) 批量获取信息
6. 数据更新：(可选) 使用 [DLsiteMetadata](https://github.com/Mysterken/DLsiteMetadata) 导入图标

## 提供的字段
+ 名称
  > 导入阶段：导入 bangumi 日语原文作为 Playnite 名称 <br>
    数据更新阶段: Playnite 库中游戏名称与 bangumi 日语原文完全相同时，更新数据   
+ 用户评分
  > 若无评分则用户评分为 bangumi 评价 * 10 <br>
    bangumi 未评分时，用户评分留空
+ 标签
  > bangumi 我的标签 <br>
    标签不存在时，自动创建标签
+ 高级 -> 上次游玩
  > 上次游玩不存在时，设置为 bangumi 收藏时间
+ 高级 -> 添加日期
  > 强制修改添加日期为 bangumi 收藏时间
+ 高级 -> 备注
  > 备注不存在且 bangumi 有吐槽，设置为吐槽

## 开始使用

### 1. 运行 `get_game_from_bgm.py` 获取用户游戏收藏

将你的 `user id` 和 `access token` 填入 `get_game_from_bgm.py` 中

```markdown
63 username = ""  # 替换成目标用户的用户ID
64 access_token = ""  # 如果要获取自己私有的收藏，需要填写 access_token
```

运行 `get_game_from_bgm.py` 

```
python get_game_from_bgm.py
```

将在工作目录下生成 `games.json` 文件，json 格式为

```json
[
  {
    "name": "ゼルダの伝説 ブレス オブ ザ ワイルド",
    "score": 10,
    "updated_at": "2023-06-15T12:34:56+08:00",
    "tags": ["Switch", "RPG", "神作"],
    "comment": "开放世界巅峰之作"
  }
]
```

### 2. 运行 `name_to_exe.py` 批量生成游戏 exe以便 Playnite 导入


运行 `name_to_exe.py` 批量生成空白exe

```
python get_game_from_bgm.py
```

将在当前目录下生成 `ExeFiles` 文件夹，文件夹下为每个游戏日语原名的文件夹，再往下是 exe 文件

```aiignore
├─ games.json
├─ ......
└─ ExeFiles/
   └─ Gamename/
      └─ Gamename.exe
```

导入结束后可以删除

## 3. 使用 Playnite 导入空白游戏

`playnite` -> `添加游戏` -> `自动扫描` -> `扫描文件夹` 选择 `ExeFiles` 文件夹

全选 并 添加游戏

## 4. 数据更新：Playnite 运行 `update.ps1` 脚本，导入用户评分、标签、上次游玩、添加日期、备注。

### 1. 要求
至少安装并启用了一个Powershell扩展, 如果你没有安装，你可以通过打开这个安装一个

在浏览器打开
```markdown
playnite://playnite/installaddon/Links_Sorter
```
### 2. 在 `update.ps1` 中设置 `games.json` 位置
打开 `update.ps1` ，添加 `games.json` 的绝对路径
```markdown
7 $jsonPath = " json Absolute path "  # 请替换为实际绝对路径
```

### 3. 运行

`playnite` -> `扩展` -> `交互式 SDK PowerShell`

在 交互式 SDK PowerShell 中复制 `update.ps1` 中的 step 1，运行
```shell
# Step 1: 连接 Playnite 会话
# Enter-PSHostProcess -Name Playnite.DesktopApp  # 若不是从 Playnite 打开，则需要运行
$PlayniteApi = (Get-Runspace)[-2].SessionStateProxy.GetVariable("PlayniteApi")
$PlayniteApi.Dialogs.ShowMessage("Connected to Playnite session")
```
运行后， Playnite 弹出消息窗口则链接成功

复制 `update.ps1` 中的 step 2，运行
```shell
# Step 2: 配置 JSON 文件路径
$jsonPath = " json Absolute path "  # 请替换为实际绝对路径
$jsonContent = Get-Content $jsonPath -Raw -Encoding UTF8
$gamesData = $jsonContent | ConvertFrom-Json

$changedCount = 0

```
复制 `update.ps1` 中的 step 3，运行
```shell
# Step 3: 遍历 Playnite 数据库中所有游戏
......
```
成功导入数据

## 5. 数据更新：(强烈建议) 使用 [Playnite Bangumi Metadata Provider](https://github.com/Ivanlon30000/PlayniteBangumiMetadata) 批量获取信息

`playnite` -> `库` -> `下载资料数据`

资料数据导入根据需求选择 bangumi

## 6. 数据更新：(可选) 使用 [DLsiteMetadata](https://github.com/Mysterken/DLsiteMetadata) 导入图标

该方法导入的游戏没有图标 (icon)，可以在`playnite` -> `库` -> `下载资料数据`

资料数据导入的`图标`选择`DLsite`、`官方商店`或者`IGDB`