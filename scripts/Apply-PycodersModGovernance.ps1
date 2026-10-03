[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$Repo,
    [switch]$All,
    [switch]$Audit
)

$ErrorActionPreference = 'Stop'
$owner = 'PycodersMod'
$repositories = @(
    '.github', 'CustomShapezAPI', 'Facade', 'TaCZinTetra',
    'TetraHolographicBlueprint', 'JournalMod', 'CarpetPlayerAddition',
    'PoetryCloudPlanets', 'CustomTamingFramework',
    'CreateProbabilityTuning', 'SharecodeChest', 'MinecraftModTestLauncher'
)

if (-not $Audit -and -not $All -and [string]::IsNullOrWhiteSpace($Repo)) {
    throw 'Specify -Repo <name>, -All, or -Audit.'
}
$ghCommand = Get-Command gh -ErrorAction SilentlyContinue
$ghPath = $null
if ($ghCommand) { $ghPath = $ghCommand.Source }
if (-not $ghCommand -and $env:ProgramFiles) {
    $candidate = Join-Path $env:ProgramFiles 'GitHub CLI\gh.exe'
    if (Test-Path $candidate) { $ghPath = $candidate }
}
if (-not $ghPath) { throw 'GitHub CLI (gh) was not found.' }
$login = & $ghPath api user --jq .login
if ($LASTEXITCODE -ne 0 -or $login.Trim() -cne 'ZYQ-2020') {
    throw 'GitHub CLI must be authenticated as ZYQ-2020.'
}
$actorId = [int](& $ghPath api user --jq .id)
if ($LASTEXITCODE -ne 0 -or $actorId -le 0) { throw 'Could not resolve the authenticated account ID.' }
if ($All -and -not $Audit) {
    $canary = & $ghPath api "repos/$owner/.github/rulesets?includes_parents=false" | ConvertFrom-Json
    if ($LASTEXITCODE -ne 0 -or @($canary | Where-Object name -eq 'PycodersMod Collaboration Gate').Count -ne 1 -or
        @($canary | Where-Object name -eq 'PycodersMod History Safety').Count -ne 1) {
        throw 'Apply and verify the .github canary rulesets before using -All.'
    }
}

function Invoke-GhJson([string]$Endpoint) {
    $json = & $ghPath api $Endpoint
    if ($LASTEXITCODE -ne 0) { throw "GitHub API request failed: $Endpoint" }
    if ([string]::IsNullOrWhiteSpace(($json -join ''))) { return $null }
    return ($json -join "`n") | ConvertFrom-Json
}

function Set-RepositoryRuleset {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param([string]$Repository, [hashtable]$Definition)
    $endpoint = "repos/$owner/$Repository/rulesets?includes_parents=false"
    $existing = @(Invoke-GhJson $endpoint | Where-Object name -eq $Definition.name)
    if ($existing.Count -gt 1) { throw "Duplicate owned ruleset name in $Repository." }
    $payloadPath = Join-Path ([IO.Path]::GetTempPath()) ("pycoders-ruleset-{0}.json" -f [guid]::NewGuid())
    try {
        $Definition | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $payloadPath -Encoding utf8
        if ($existing.Count -eq 1) {
            $writeEndpoint = "repos/$owner/$Repository/rulesets/$($existing[0].id)"
            $method = 'PUT'
        } else {
            $writeEndpoint = "repos/$owner/$Repository/rulesets"
            $method = 'POST'
        }
        if ($PSCmdlet.ShouldProcess("$owner/$Repository", "$method $($Definition.name)")) {
            & $ghPath api --method $method --input $payloadPath $writeEndpoint | Out-Null
            if ($LASTEXITCODE -ne 0) { throw "Could not apply $($Definition.name) to $Repository." }
        }
    } finally {
        Remove-Item -LiteralPath $payloadPath -Force -ErrorAction SilentlyContinue
    }
}

function Test-RepositoryGovernance([string]$Repository) {
    $rulesets = @(Invoke-GhJson "repos/$owner/$Repository/rulesets?includes_parents=true")
    $mainRules = @(Invoke-GhJson "repos/$owner/$Repository/rules/branches/main")
    $collaboration = @($rulesets | Where-Object name -eq 'PycodersMod Collaboration Gate')
    $history = @($rulesets | Where-Object name -eq 'PycodersMod History Safety')
    $collabRules = if ($collaboration.Count -eq 1) { @($collaboration[0].rules) } else { @() }
    $historyRules = if ($history.Count -eq 1) { @($history[0].rules) } else { @() }
    $collabTypes = @($collabRules | ForEach-Object type)
    $historyTypes = @($historyRules | ForEach-Object type)
    $pull = $collabRules | Where-Object type -eq 'pull_request' | Select-Object -First 1
    $approvers = if ($collaboration.Count -eq 1) { @($collaboration[0].bypass_actors) } else { @() }
    $mainTypes = @($mainRules | ForEach-Object type)
    $checks = [ordered]@{
        Repository = $Repository
        CollaborationGate = ($collaboration.Count -eq 1 -and $collaboration[0].enforcement -eq 'active')
        SingleCodeOwnerBypass = ($approvers.Count -eq 1 -and $approvers[0].actor_id -eq $actorId -and $approvers[0].actor_type -eq 'User' -and $approvers[0].bypass_mode -eq 'always')
        PullRequestAndOneApproval = ($null -ne $pull -and $pull.parameters.required_approving_review_count -eq 1 -and $pull.parameters.require_code_owner_review -eq $true)
        HistorySafety = ($history.Count -eq 1 -and $history[0].enforcement -eq 'active' -and $historyTypes -contains 'deletion' -and $historyTypes -contains 'non_fast_forward' -and @($history[0].bypass_actors).Count -eq 0)
        MainRequiresPullRequest = ($mainTypes -contains 'pull_request')
        MainBlocksForcePush = ($mainTypes -contains 'non_fast_forward')
        MainBlocksDeletion = ($mainTypes -contains 'deletion')
        RulesetIds = (@($collaboration[0].id, $history[0].id) -join ',')
    }
    [pscustomobject]$checks
}

if ($Audit) {
    $targets = if ($Repo) { @($Repo) } else { $repositories }
    $auditResults = foreach ($name in $targets) { Test-RepositoryGovernance $name }
    $auditResults | Format-Table -AutoSize
    if (@($auditResults | Where-Object { -not $_.CollaborationGate -or -not $_.SingleCodeOwnerBypass -or -not $_.PullRequestAndOneApproval -or -not $_.HistorySafety -or -not $_.MainRequiresPullRequest -or -not $_.MainBlocksForcePush -or -not $_.MainBlocksDeletion }).Count -gt 0) { exit 1 }
    exit 0
}

$targets = if ($All) { $repositories } else { @($Repo) }
foreach ($name in $targets) {
    if ($repositories -cnotcontains $name) { throw "Repository is not in the explicit allowlist: $name" }
    $collaboration = @{
        name = 'PycodersMod Collaboration Gate'
        target = 'branch'
        enforcement = 'active'
        bypass_actors = @(@{ actor_id = $actorId; actor_type = 'User'; bypass_mode = 'always' })
        conditions = @{ ref_name = @{ include = @('~DEFAULT_BRANCH'); exclude = @() } }
        rules = @(@{ type = 'pull_request'; parameters = @{ required_approving_review_count = 1; dismiss_stale_reviews_on_push = $true; require_code_owner_review = $true; require_last_push_approval = $false; allowed_merge_methods = @('merge', 'squash', 'rebase') } })
    }
    $historySafety = @{
        name = 'PycodersMod History Safety'
        target = 'branch'
        enforcement = 'active'
        bypass_actors = @()
        conditions = @{ ref_name = @{ include = @('~DEFAULT_BRANCH'); exclude = @() } }
        rules = @(@{ type = 'deletion' }, @{ type = 'non_fast_forward' })
    }
    Set-RepositoryRuleset $name $collaboration
    Set-RepositoryRuleset $name $historySafety
    Test-RepositoryGovernance $name | Format-List
}
