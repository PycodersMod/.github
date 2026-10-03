[CmdletBinding(DefaultParameterSetName = 'Workspace')]
param(
    [Parameter(Mandatory, ParameterSetName = 'Workspace')][string]$WorkspaceRoot,
    [Parameter(Mandatory, ParameterSetName = 'Repository')][string]$RepositoryRoot,
    [string]$MinecraftReleaseManifestPath
)

$ErrorActionPreference = 'Stop'
$expectedRepositories = @(
    'CustomShapezAPI', 'Facade', 'TaCZinTetra', 'TetraHolographicBlueprint', 'JournalMod',
    'CarpetPlayerAddition', 'PoetryCloudPlanets', 'CustomTamingFramework',
    'CreateProbabilityTuning', 'SharecodeChest'
)
$loaderOrder = @('fabric', 'forge', 'neoforge', 'quilt', 'liteloader', 'legacy-fabric', 'ornithe', 'rift', 'modloader', 'modloadermp', 'jarmod', 'other')
$loaderNames = @{
    fabric = 'Fabric'; forge = 'Forge'; neoforge = 'NeoForge'; quilt = 'Quilt'; liteloader = 'LiteLoader'
    'legacy-fabric' = 'Legacy Fabric'; ornithe = 'Ornithe Loader'; rift = 'Rift'; modloader = 'ModLoader'
    modloadermp = 'ModLoaderMP'; jarmod = 'JarMod'; other = 'Other'
}
$script:releaseTimes = $null
$script:manifestPath = $MinecraftReleaseManifestPath

function Add-Finding {
    param([System.Collections.Generic.List[string]]$Findings, [string]$Message)
    $Findings.Add($Message)
}

function Get-TableRows {
    param([Parameter(Mandatory)][string]$TableText)
    try {
        $xml = [xml]('<root>' + $TableText + '</root>')
    } catch {
        throw "支持目标表格 HTML/XML 结构无效：$($_.Exception.Message)"
    }
    return @($xml.SelectNodes('/root/table/tr | /root/table/thead/tr | /root/table/tbody/tr'))
}

function Get-ReleaseTimes {
    if ($script:releaseTimes) { return $script:releaseTimes }
    if ($script:manifestPath) {
        if (-not (Test-Path -LiteralPath $script:manifestPath -PathType Leaf)) { throw "Minecraft release manifest 不存在：$script:manifestPath" }
        $manifest = Get-Content -LiteralPath $script:manifestPath -Raw | ConvertFrom-Json -ErrorAction Stop
    } else {
        try {
            $manifest = Invoke-RestMethod -Uri 'https://piston-meta.mojang.com/mc/game/version_manifest_v2.json' -TimeoutSec 20
        } catch {
            throw '多版本目标需要 Mojang release manifest 以验证发布日期顺序；网络不可用时请用 -MinecraftReleaseManifestPath 指定本地 manifest。'
        }
    }
    $script:releaseTimes = @{}
    foreach ($version in @($manifest.versions | Where-Object type -eq 'release')) {
        if ($version.id -and $version.releaseTime) { $script:releaseTimes[[string]$version.id] = [DateTimeOffset]::Parse([string]$version.releaseTime) }
    }
    return $script:releaseTimes
}

function Get-CompatibilityReleaseTime {
    param([Parameter(Mandatory)][string]$VersionLine)
    $releaseTimes = Get-ReleaseTimes
    $ids = [regex]::Matches($VersionLine, '\d+\.\d+(?:\.\d+)?') | ForEach-Object Value
    if (-not $ids) { throw "Minecraft 兼容线无法解析为正式版本：$VersionLine" }
    $times = foreach ($id in $ids) {
        if (-not $releaseTimes.ContainsKey($id)) { throw "Mojang release manifest 不含目标版本：$id" }
        $releaseTimes[$id]
    }
    return ($times | Sort-Object -Descending | Select-Object -First 1)
}

function Get-RepositoryReadmeAudit {
    param([Parameter(Mandatory)][string]$Root)
    $rootPath = (Resolve-Path -LiteralPath $Root).Path
    $repositoryName = Split-Path $rootPath -Leaf
    $origin = git -C $rootPath remote get-url origin 2>$null
    if ($LASTEXITCODE -eq 0 -and $origin -match 'github\.com[:/]PycodersMod/([^/.]+)(?:\.git)?$') { $repositoryName = $Matches[1] }
    $readmePath = Join-Path $rootPath 'README.md'
    if (-not (Test-Path -LiteralPath $readmePath -PathType Leaf)) { throw "README.md 不存在：$rootPath" }
    $content = Get-Content -LiteralPath $readmePath -Raw -Encoding utf8
    $findings = [System.Collections.Generic.List[string]]::new()
    $templatePattern = '(?s)\$\(@\{[^}]*\}\.[A-Za-z_][A-Za-z0-9_]*\)|\$\{[^}]+\}|@\{[^}]*\}\.[A-Za-z_][A-Za-z0-9_]*'
    $templateMatches = [regex]::Matches($content, $templatePattern)
    foreach ($match in $templateMatches) { Add-Finding $findings "未解析模板表达式：$($match.Value)" }

    $headingPattern = '(?im)^#{1,6}[ \t]+(支持目标|Supported Targets)[ \t]*#*[ \t]*$'
    $headings = [regex]::Matches($content, $headingPattern)
    if ($headings.Count -ne 1) {
        Add-Finding $findings ('README 必须且只能有一个“支持目标”标题；实际为 ' + $headings.Count + ' 个。')
        return [pscustomobject]@{ Repository = $repositoryName; Targets = @(); ExternalUrlCount = 0; TemplateLeakCount = $templateMatches.Count; Findings = $findings.ToArray() }
    }
    if ($headings[0].Groups[1].Value -cne '支持目标') { Add-Finding $findings '支持目标标题必须使用中文。' }
    $afterHeading = $content.Substring($headings[0].Index + $headings[0].Length)
    $nextHeading = [regex]::Match($afterHeading, '(?m)^#{1,6}[ \t]+')
    $section = if ($nextHeading.Success) { $afterHeading.Substring(0, $nextHeading.Index) } else { $afterHeading }
    $tables = [regex]::Matches($section, '(?is)<table\b[^>]*>.*?</table\s*>')
    if ($tables.Count -ne 1) {
        Add-Finding $findings '“支持目标”章节必须且只能包含一个 HTML 表格。'
        return [pscustomobject]@{ Repository = $repositoryName; Targets = @(); ExternalUrlCount = 0; TemplateLeakCount = $templateMatches.Count; Findings = $findings.ToArray() }
    }
    $tableText = $tables[0].Value
    $externalUrlCount = [regex]::Matches($tableText, '(?i)href\s*=\s*["''][^"'']*(?:https?:|mailto:|//)[^"'']*["'']').Count
    if ($externalUrlCount -gt 0) { Add-Finding $findings "支持目标表包含外链：$externalUrlCount 个；href 必须是仓库内相对目录。" }

    try { $rows = @(Get-TableRows -TableText $tableText) }
    catch { Add-Finding $findings $_.Exception.Message; $rows = @() }
    if ($rows.Count -lt 2) { Add-Finding $findings '支持目标表必须有一行 Loader/Minecraft 表头及至少一个目标行。' }
    if ($rows.Count -gt 0) {
        $headers = @($rows[0].SelectNodes('./th | ./td') | ForEach-Object { ([System.Net.WebUtility]::HtmlDecode($_.InnerText)).Trim() })
        if (($headers -join '|') -cne 'Loader|Minecraft') { Add-Finding $findings '支持目标表必须恰好使用 Loader、Minecraft 两列。' }
    }

    $targets = [System.Collections.Generic.List[object]]::new()
    $activeLoader = $null
    $activeLoaderRows = 0
    $seenLoaders = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($row in @($rows | Select-Object -Skip 1)) {
        $cells = @($row.SelectNodes('./td'))
        if ($cells.Count -notin @(1, 2)) { Add-Finding $findings '目标表每行必须含有 Loader 与 Minecraft 单元格，或使用合法 rowspan。'; continue }
        if ($cells.Count -eq 2) {
            $loaderCell = $cells[0]
            $loaderAnchor = @($loaderCell.SelectNodes('.//a'))
            if ($loaderAnchor.Count -ne 1) { Add-Finding $findings 'Loader 单元格必须包含且只包含一个目录链接。'; continue }
            $loaderHref = [System.Net.WebUtility]::HtmlDecode([string]$loaderAnchor[0].GetAttribute('href')).Trim()
            $loaderText = ([System.Net.WebUtility]::HtmlDecode($loaderAnchor[0].InnerText)).Trim()
            $activeLoader = [pscustomobject]@{ Href = $loaderHref; Text = $loaderText; Slug = $null }
            $rowspan = if ($loaderCell.HasAttribute('rowspan')) { [int]$loaderCell.GetAttribute('rowspan') } else { 1 }
            if ($rowspan -lt 1) { Add-Finding $findings 'Loader rowspan 必须为正整数。'; $rowspan = 1 }
            $activeLoaderRows = $rowspan - 1
        } elseif (-not $activeLoader -or $activeLoaderRows -lt 1) {
            Add-Finding $findings '缺少 Loader 单元格且无法由有效 rowspan 继承。'; continue
        } else {
            $activeLoaderRows--
        }

        $minecraftCell = $cells[-1]
        $minecraftAnchor = @($minecraftCell.SelectNodes('.//a'))
        if ($minecraftAnchor.Count -ne 1) { Add-Finding $findings 'Minecraft 单元格必须包含且只包含一个项目目录链接。'; continue }
        $minecraftHref = [System.Net.WebUtility]::HtmlDecode([string]$minecraftAnchor[0].GetAttribute('href')).Trim()
        $minecraftText = ([System.Net.WebUtility]::HtmlDecode($minecraftAnchor[0].InnerText)).Trim()
        $versionMatch = [regex]::Match($minecraftHref, '^([a-z0-9-]+)/([^/]+)/$')
        if (-not $versionMatch.Success) { Add-Finding $findings "Minecraft href 必须形如 <loader>/<compatibility-line>/：$minecraftHref"; continue }
        $versionLoader = $versionMatch.Groups[1].Value
        $versionLine = $versionMatch.Groups[2].Value
        if ($activeLoader.Href -cne "$versionLoader/") { Add-Finding $findings "Loader href 与 Minecraft 项目路径不一致：$($activeLoader.Href) / $minecraftHref" }
        if ($cells.Count -eq 2 -and -not $seenLoaders.Add($versionLoader)) { Add-Finding $findings "同一 Loader 的多个目标必须使用一个带 rowspan 的 Loader 单元格：$versionLoader" }
        $activeLoader.Slug = $versionLoader
        if ($loaderNames.ContainsKey($versionLoader) -and $activeLoader.Text -cne $loaderNames[$versionLoader]) { Add-Finding $findings "Loader 名称与目录 slug 不一致：$($activeLoader.Text) / $versionLoader" }
        if (-not $loaderNames.ContainsKey($versionLoader) -and $activeLoader.Text -notmatch ('(?i)^' + [regex]::Escape($versionLoader) + '$')) { Add-Finding $findings "未知 Loader 名称必须与目录 slug 对应：$($activeLoader.Text) / $versionLoader" }

        foreach ($href in @($activeLoader.Href, $minecraftHref)) {
            if ($href -match '^(?i)(?:[a-z][a-z0-9+.-]*:|//|/|\\)' -or $href -match '(^|/)\.\.?(/|$)' -or $href.Contains('\')) { Add-Finding $findings "目录 href 必须是无路径穿越的相对路径：$href"; continue }
            $relativePath = $href.TrimEnd('/') -replace '/', [IO.Path]::DirectorySeparatorChar
            if (-not (Test-Path -LiteralPath (Join-Path $rootPath $relativePath) -PathType Container)) { Add-Finding $findings "链接目标目录不存在：$href" }
        }
        $normalizedDisplay = $minecraftText.Replace('–', '-').Replace('—', '-')
        if ($normalizedDisplay -cne $versionLine) { Add-Finding $findings "Minecraft 显示版本与目录名不一致：$minecraftText / $versionLine" }
        $targets.Add([pscustomobject]@{ Loader = $activeLoader.Text; LoaderSlug = $versionLoader; LoaderHref = $activeLoader.Href; Minecraft = $minecraftText; MinecraftHref = $minecraftHref; ReleaseTime = $null })
    }

    $previousLoaderIndex = -1
    foreach ($target in $targets) {
        $loaderIndex = [array]::IndexOf($loaderOrder, $target.LoaderSlug)
        if ($loaderIndex -lt 0) { Add-Finding $findings "Loader 不在固定顺序表：$($target.LoaderSlug)"; continue }
        if ($loaderIndex -lt $previousLoaderIndex) { Add-Finding $findings 'Loader 行未遵循冻结顺序：Fabric、Forge、NeoForge、Quilt、LiteLoader、Legacy Fabric、Ornithe Loader、Rift、ModLoader、ModLoaderMP、JarMod、Other。' }
        $previousLoaderIndex = $loaderIndex
    }
    foreach ($group in @($targets | Group-Object LoaderSlug | Where-Object Count -gt 1)) {
        try {
            $ordered = @($group.Group | ForEach-Object { $_.ReleaseTime = Get-CompatibilityReleaseTime -VersionLine ([string]$_.Minecraft); $_ } | Sort-Object ReleaseTime -Descending)
            if (($ordered.Minecraft -join '|') -cne (($group.Group).Minecraft -join '|')) { Add-Finding $findings "同一 Loader 的 Minecraft 版本未按 Mojang releaseTime 倒序：$($group.Name)" }
        } catch { Add-Finding $findings $_.Exception.Message }
    }

    return [pscustomobject]@{ Repository = $repositoryName; Targets = $targets.ToArray(); ExternalUrlCount = $externalUrlCount; TemplateLeakCount = $templateMatches.Count; Findings = $findings.ToArray() }
}

if ($PSCmdlet.ParameterSetName -eq 'Repository') {
    $roots = @((Resolve-Path -LiteralPath $RepositoryRoot).Path)
    $workspaceFindings = @()
} else {
    $workspace = (Resolve-Path -LiteralPath $WorkspaceRoot).Path
    $roots = @()
    foreach ($directory in Get-ChildItem -LiteralPath $workspace -Directory -Force) {
        if (-not (Test-Path -LiteralPath (Join-Path $directory.FullName '.git'))) { continue }
        $remote = git -C $directory.FullName remote get-url origin 2>$null
        if ($LASTEXITCODE -ne 0 -or $remote -notmatch 'github\.com[:/]PycodersMod/([^/.]+)(?:\.git)?$') { continue }
        if ($Matches[1] -in $expectedRepositories) { $roots += $directory.FullName }
    }
    $foundNames = @($roots | ForEach-Object { (git -C $_ remote get-url origin) -replace '^.*github\.com[:/]PycodersMod/','' -replace '\.git$','' })
    $workspaceFindings = @($expectedRepositories | Where-Object { $_ -notin $foundNames } | ForEach-Object { "Workspace 缺少 Mod 仓库：$_" })
}

$results = foreach ($root in $roots) {
    try { Get-RepositoryReadmeAudit -Root $root }
    catch { [pscustomobject]@{ Repository = (Split-Path $root -Leaf); Targets = @(); ExternalUrlCount = 0; TemplateLeakCount = 0; Findings = @($_.ToString()) } }
}
$failures = @($results | Where-Object { $_.Findings.Count -gt 0 })
foreach ($finding in $workspaceFindings) { Write-Output ("失败 工作区：{0}" -f $finding) }
foreach ($result in $results) {
    if ($result.Findings.Count -eq 0) { Write-Output ("PASS {0}：目标数={1}，表格外链={2}，模板残留={3}" -f $result.Repository, $result.Targets.Count, $result.ExternalUrlCount, $result.TemplateLeakCount) }
    else { foreach ($finding in $result.Findings) { Write-Output ("失败 {0}：{1}" -f $result.Repository, $finding) } }
}
if ($failures.Count -gt 0 -or $workspaceFindings.Count -gt 0) { exit 1 }
Write-Output ("PASS：共审计 {0} 个 Mod README 仓库。" -f $results.Count)
