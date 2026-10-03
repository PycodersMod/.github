[CmdletBinding()]
param([Parameter(Mandatory)][string]$WorkspaceRoot)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $WorkspaceRoot).Path
$dynamicValues = [System.Collections.Generic.List[string]]::new()
foreach ($value in @($env:USERPROFILE, $env:TEMP, $env:TMP, $env:COMPUTERNAME, $env:HOSTNAME, $root)) {
    if (-not [string]::IsNullOrWhiteSpace($value) -and $value.Length -ge 3) { $dynamicValues.Add($value.TrimEnd('\', '/')) }
}
$privateEmail = (git config --get user.email 2>$null)
if ($privateEmail -and $privateEmail -notmatch '^[0-9]+\+ZYQ-2020@users\.noreply\.github\.com$') { $dynamicValues.Add($privateEmail.Trim()) }
$proxyValues = @($env:HTTP_PROXY, $env:HTTPS_PROXY, $env:ALL_PROXY, $env:http_proxy, $env:https_proxy, $env:all_proxy) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
$findings = [System.Collections.Generic.List[object]]::new()

$repositories = Get-ChildItem -LiteralPath $root -Directory | Where-Object {
    $remote = git -C $_.FullName remote get-url origin 2>$null
    $LASTEXITCODE -eq 0 -and $remote -match 'github\.com[:/]PycodersMod/'
}
foreach ($repository in $repositories) {
    $repoRoot = $repository.FullName
    $tracked = git -C $repoRoot ls-files --cached --others --exclude-standard
    if ($LASTEXITCODE -ne 0) { continue }
    foreach ($relative in ($tracked | Where-Object { $_ })) {
        $fullPath = Join-Path $repoRoot $relative
        if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) { continue }
        $file = Get-Item -LiteralPath $fullPath
        if ($file.Length -gt 5MB) { continue }
        $bytes = [IO.File]::ReadAllBytes($fullPath)
        if ($bytes -contains 0) { continue }
        $content = [Text.Encoding]::UTF8.GetString($bytes)
        $relativePath = [IO.Path]::GetRelativePath($repoRoot, $fullPath).Replace('\', '/')
        foreach ($value in $dynamicValues) {
            if ($value.Length -ge 3 -and $content.IndexOf($value, [StringComparison]::OrdinalIgnoreCase) -ge 0) {
                $findings.Add([pscustomobject]@{ Repository=$repository.Name; Path=$relativePath; Category='local-path-or-identity' }); break
            }
        }
        $networkLabel = 'prox' + 'y'
        $localAddress = '127' + '.0.0.1'
        $localHostLabel = 'local' + 'host'
        if ($content -match ("(?i)($networkLabel.{0,100}($localAddress|$localHostLabel)|(?:$localAddress|$localHostLabel).{0,100}$networkLabel)")) {
            $findings.Add([pscustomobject]@{ Repository=$repository.Name; Path=$relativePath; Category='local-proxy-setting' })
        }
        $emailScanContent = [regex]::Replace($content, '(?i)https?://[^\s/@:]+:[^\s/@]+@', '<url-auth>@')
        if ($emailScanContent -match '(?i)\b[A-Z0-9._%+-]+@(?!users\.noreply\.github\.com\b)(?!example\.(?:com|net|org)\b)[A-Z0-9.-]+\.[A-Z]{2,}\b') {
            $findings.Add([pscustomobject]@{ Repository=$repository.Name; Path=$relativePath; Category='non-noreply-email' })
        }
        foreach ($proxy in $proxyValues) {
            if ($proxy.Length -ge 5 -and $content.IndexOf($proxy, [StringComparison]::OrdinalIgnoreCase) -ge 0) {
                $findings.Add([pscustomobject]@{ Repository=$repository.Name; Path=$relativePath; Category='local-proxy-value' }); break
            }
        }
    }
}

if ($findings.Count -eq 0) { 'PASS: no dynamic local path, identity, proxy, or non-noreply email finding in repository trees.'; exit 0 }
$findings | Sort-Object Repository,Path,Category -Unique | Format-Table -AutoSize
exit 1
