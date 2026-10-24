param(
    [ValidateSet('debug', 'profile', 'release')]
    [string]$Mode = 'debug',
    [string[]]$AdditionalArguments = @()
)

$commit = (& git rev-parse --short HEAD).Trim()
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($commit)) {
    throw 'Não foi possível obter o commit Git atual.'
}

$worktreeStatus = & git status --porcelain
if ($LASTEXITCODE -ne 0) {
    throw 'Não foi possível verificar o estado do worktree.'
}
if ($worktreeStatus) {
    $commit = "$commit-dirty"
}

& flutter build apk "--$Mode" "--dart-define=APP_GIT_COMMIT=$commit" @AdditionalArguments
exit $LASTEXITCODE
