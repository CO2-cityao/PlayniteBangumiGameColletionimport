# Step 1: 连接 Playnite 会话
# Enter-PSHostProcess -Name Playnite.DesktopApp  # 若不是从 Playnite 打开，则需要运行
$PlayniteApi = (Get-Runspace)[-2].SessionStateProxy.GetVariable("PlayniteApi")
$PlayniteApi.Dialogs.ShowMessage("Connected to Playnite session")

# Step 2: 配置 JSON 文件路径
$jsonPath = " json Absolute path "  # 请替换为实际绝对路径
$jsonContent = Get-Content $jsonPath -Raw -Encoding UTF8
$gamesData = $jsonContent | ConvertFrom-Json

$changedCount = 0

# Step 3: 遍历 Playnite 数据库中所有游戏
foreach ($game in $PlayniteApi.Database.Games) {
    # 查找 JSON 中匹配的游戏
    $jsonGame = $gamesData | Where-Object { $_.name -eq $game.Name }
    if ($jsonGame) {
        $updateNeeded = $false

        # 检查用户评分（UserScore 为 0 表示未评分）
        if (($jsonGame.score -ne 0) -and (-not $game.UserScore -or $game.UserScore -eq 0)) {
            $game.UserScore = [int]($jsonGame.score * 10)
            $updateNeeded = $true
        }

        # 检查备注：只有 JSON 中有 comment 才修改
        if ($jsonGame.PSObject.Properties.Name -contains "comment" -and -not $game.Notes) {
            $game.Notes = $jsonGame.comment
            $updateNeeded = $true
        }

        # 标签处理：确保存在标签，再绑定到游戏
        if ($jsonGame.tags -and $jsonGame.tags.Count -gt 0) {
            foreach ($tagName in $jsonGame.tags) {
                # 查找数据库中是否已有该标签
                $tag = $PlayniteApi.Database.Tags | Where-Object { $_.Name -eq $tagName }

                # 如果没有就新建，必须使用 Add 返回的对象
                if (-not $tag) {
                    $newTag = New-Object Playnite.SDK.Models.Tag
                    $newTag.Name = $tagName
                    $tag = $PlayniteApi.Database.Tags.Add($newTag)  # 这里 Add 返回的对象才有 Id
                }

                # 确保 $tag 和 $tag.Id 有效
                if ($tag -and $tag.Id -and (-not ($game.TagIds -contains $tag.Id))) {
                    # 构造新的 TagId 列表
                    $newTagList = New-Object 'System.Collections.Generic.List[System.Guid]'
                    foreach ($tid in $game.TagIds) {
                        if ($tid) { $newTagList.Add([guid]$tid) }
                    }
                    $newTagList.Add([guid]$tag.Id)

                    # 覆盖写回
                    $game.TagIds = $newTagList
                    $updateNeeded = $true
                }
            }
        }

        # 检查上次游玩
        if (-not $game.LastActivity) {
            $game.LastActivity = [datetime]::Parse($jsonGame.updated_at).Date
            $updateNeeded = $true
        }

        # 检查添加日期
        if ($game.Added) {
            $game.Added = [datetime]::Parse($jsonGame.updated_at).Date
            $updateNeeded = $true
        }

        # 如果有更新，保存游戏
        if ($updateNeeded) {
            $PlayniteApi.Database.Games.Update($game)
            $changedCount++
        }
    }
}

# 显示修改结果
$PlayniteApi.Dialogs.ShowMessage("Updated metadata for $changedCount game(s)")
