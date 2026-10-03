$ErrorActionPreference = 'Stop'

$script:pwsh = (Get-Command pwsh -ErrorAction Stop).Source
$script:audit = Join-Path $PSScriptRoot '..\scripts\Test-ModReadmeTargets.ps1'
$script:testRoot = Join-Path ([IO.Path]::GetTempPath()) ('PycodersMod-Readme-Audit-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $script:testRoot -Force | Out-Null

function New-ReadmeFixture {
    param(
        [Parameter(Mandatory)][string]$Name,
        [string]$LoaderHref = 'forge/',
        [string]$MinecraftHref = 'forge/1.20.1/',
        [string]$LoaderText = 'Forge',
        [string]$MinecraftText = '1.20.1',
        [string]$ExtraTableHref = ''
    )
    $repo = Join-Path $script:testRoot $Name
    New-Item -ItemType Directory -Path (Join-Path $repo 'forge/1.20.1') -Force | Out-Null
    $otherHref = if ($ExtraTableHref) { "<a href=`"$ExtraTableHref`">Forge 上游</a>" } else { '' }
    $readme = @"
# Fixture

## 支持目标

<table>
<thead><tr><th>Loader</th><th>Minecraft</th></tr></thead>
<tbody><tr><td><a href="$LoaderHref">$LoaderText</a></td><td><a href="$MinecraftHref">$MinecraftText</a></td></tr></tbody>
</table>

$otherHref
"@
    Set-Content -LiteralPath (Join-Path $repo 'README.md') -Value $readme -Encoding utf8
    return $repo
}

function Invoke-ReadmeAudit {
    param([Parameter(Mandatory)][string]$RepositoryRoot, [string]$ManifestPath)
    $arguments = @('-NoProfile', '-File', $script:audit, '-RepositoryRoot', $RepositoryRoot)
    if ($ManifestPath) { $arguments += @('-MinecraftReleaseManifestPath', $ManifestPath) }
    $output = @(& $script:pwsh @arguments 2>&1)
    [pscustomobject]@{ ExitCode = $LASTEXITCODE; Output = ($output -join "`n") }
}

function Assert-Audit {
    param(
        [Parameter(Mandatory)]$Result,
        [Parameter(Mandatory)][bool]$ShouldPass,
        [string]$ExpectedText
    )
    if ($ShouldPass -and $Result.ExitCode -ne 0) { throw "Expected audit PASS, got exit $($Result.ExitCode): $($Result.Output)" }
    if (-not $ShouldPass -and $Result.ExitCode -eq 0) { throw "Expected audit failure, got PASS: $($Result.Output)" }
    if ($ExpectedText -and $Result.Output -notmatch [regex]::Escape($ExpectedText)) { throw "Expected '$ExpectedText' in audit output: $($Result.Output)" }
}

try {
    $valid = New-ReadmeFixture -Name 'valid'
    Assert-Audit (Invoke-ReadmeAudit -RepositoryRoot $valid) -ShouldPass $true -ExpectedText 'PASS'

    $external = New-ReadmeFixture -Name 'external' -LoaderHref 'https://files.minecraftforge.net/'
    Assert-Audit (Invoke-ReadmeAudit -RepositoryRoot $external) -ShouldPass $false -ExpectedText '外链'

    $missing = New-ReadmeFixture -Name 'missing' -MinecraftHref 'forge/1.21.1/' -MinecraftText '1.21.1'
    Assert-Audit (Invoke-ReadmeAudit -RepositoryRoot $missing) -ShouldPass $false -ExpectedText '目录'

    $wrongLoader = New-ReadmeFixture -Name 'wrong-loader' -LoaderHref 'fabric/'
    Assert-Audit (Invoke-ReadmeAudit -RepositoryRoot $wrongLoader) -ShouldPass $false -ExpectedText 'Loader'

    $template = New-ReadmeFixture -Name 'template' -MinecraftHref 'forge/1.20.1/'
    Add-Content -LiteralPath (Join-Path $template 'README.md') -Value '构建目录：$(@{Loader=forge; Version=1.20.1}.Path)' -Encoding utf8
    Assert-Audit (Invoke-ReadmeAudit -RepositoryRoot $template) -ShouldPass $false -ExpectedText '模板'

    $absentTable = Join-Path $script:testRoot 'absent-table'
    New-Item -ItemType Directory -Path $absentTable -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $absentTable 'README.md') -Value "# Fixture`n`n## 支持目标`n`n这里缺少目标表格。" -Encoding utf8
    Assert-Audit (Invoke-ReadmeAudit -RepositoryRoot $absentTable) -ShouldPass $false -ExpectedText '表格'

    $englishTitle = New-ReadmeFixture -Name 'english-title'
    $englishReadme = (Get-Content -LiteralPath (Join-Path $englishTitle 'README.md') -Raw -Encoding utf8).Replace('## 支持目标', '## Supported Targets')
    Set-Content -LiteralPath (Join-Path $englishTitle 'README.md') -Value $englishReadme -Encoding utf8
    Assert-Audit (Invoke-ReadmeAudit -RepositoryRoot $englishTitle) -ShouldPass $false -ExpectedText '中文'

    $manifest = Join-Path $script:testRoot 'release-manifest.json'
    '{"versions":[{"id":"1.21.1","type":"release","releaseTime":"2024-09-03T12:00:00+00:00"},{"id":"1.20.1","type":"release","releaseTime":"2023-06-12T12:00:00+00:00"}]}' | Set-Content -LiteralPath $manifest -Encoding utf8
    $multi = Join-Path $script:testRoot 'multi-version'
    New-Item -ItemType Directory -Path (Join-Path $multi 'forge/1.21.1'), (Join-Path $multi 'forge/1.20.1') -Force | Out-Null
    $multiReadme = @'
# Fixture

## 支持目标

<table><thead><tr><th>Loader</th><th>Minecraft</th></tr></thead><tbody>
<tr><td rowspan="2"><a href="forge/">Forge</a></td><td><a href="forge/1.21.1/">1.21.1</a></td></tr>
<tr><td><a href="forge/1.20.1/">1.20.1</a></td></tr>
</tbody></table>
'@
    Set-Content -LiteralPath (Join-Path $multi 'README.md') -Value $multiReadme -Encoding utf8
    Assert-Audit (Invoke-ReadmeAudit -RepositoryRoot $multi -ManifestPath $manifest) -ShouldPass $true -ExpectedText 'PASS'
    $multiReadme = $multiReadme.Replace('<a href="forge/1.21.1/">1.21.1</a></td></tr>', '<a href="forge/1.20.1/">1.20.1</a></td></tr>').Replace('<a href="forge/1.20.1/">1.20.1</a></td></tr>' + "`n</tbody>", '<a href="forge/1.21.1/">1.21.1</a></td></tr>' + "`n</tbody>")
    Set-Content -LiteralPath (Join-Path $multi 'README.md') -Value $multiReadme -Encoding utf8
    Assert-Audit (Invoke-ReadmeAudit -RepositoryRoot $multi -ManifestPath $manifest) -ShouldPass $false -ExpectedText 'releaseTime'

    $workspace = Join-Path $script:testRoot 'workspace'
    foreach ($name in @('CustomShapezAPI','Facade','TaCZinTetra','TetraHolographicBlueprint','JournalMod','CarpetPlayerAddition','PoetryCloudPlanets','CustomTamingFramework','CreateProbabilityTuning','SharecodeChest')) {
        $loader = if ($name -eq 'CarpetPlayerAddition') { 'fabric' } elseif ($name -eq 'CreateProbabilityTuning') { 'neoforge' } else { 'forge' }
        $version = if ($name -eq 'CarpetPlayerAddition') { '1.21.6' } elseif ($name -eq 'CreateProbabilityTuning') { '1.21.1' } else { '1.20.1' }
        $repo = Join-Path $workspace $name
        $target = Join-Path $repo "$loader/$version"
        New-Item -ItemType Directory -Path $target -Force | Out-Null
        $display = if ($loader -eq 'neoforge') { 'NeoForge' } else { (Get-Culture).TextInfo.ToTitleCase($loader) }
        $readme = "# $name`n`n## 支持目标`n`n<table><thead><tr><th>Loader</th><th>Minecraft</th></tr></thead><tbody><tr><td><a href=`"$loader/`">$display</a></td><td><a href=`"$loader/$version/`">$version</a></td></tr></tbody></table>"
        Set-Content -LiteralPath (Join-Path $repo 'README.md') -Value $readme -Encoding utf8
        & git -C $repo init --quiet
        & git -C $repo remote add origin "https://github.com/PycodersMod/$name.git"
    }
    $workspaceOutput = @(& $script:pwsh -NoProfile -File $script:audit -WorkspaceRoot $workspace 2>&1)
    Assert-Audit ([pscustomobject]@{ ExitCode = $LASTEXITCODE; Output = ($workspaceOutput -join "`n") }) -ShouldPass $true -ExpectedText '共审计 10 个'

    '通过：README 目录链接审计 fixture 8/8。'
}
finally {
    Remove-Item -LiteralPath $script:testRoot -Recurse -Force -ErrorAction SilentlyContinue
}
