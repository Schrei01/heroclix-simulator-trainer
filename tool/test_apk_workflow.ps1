$ErrorActionPreference = 'Stop'
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$source = Join-Path $projectRoot 'build/app/outputs/flutter-apk/app-debug.apk'
if (-not (Test-Path -LiteralPath $source)) { throw 'Genera primero un APK debug válido para comprobar el flujo.' }
$baseFolder = [IO.Path]::GetFullPath((Join-Path $projectRoot 'build/verification/apk-workflow-tests'))
$fixture = [IO.Path]::GetFullPath((Join-Path $baseFolder ([guid]::NewGuid().ToString('N'))))
$spec = [IO.File]::ReadAllText((Join-Path $projectRoot 'pubspec.yaml'))
function Assert-True([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw $Message }
}
function Assert-Previous {
    Assert-True (Test-Path -LiteralPath (Join-Path $release 'anterior-a.apk')) 'Se borró una versión anterior tras un fallo.'
    Assert-True (Test-Path -LiteralPath (Join-Path $release 'anterior-b.apk')) 'Se borró una versión anterior tras un fallo.'
    Assert-True ((Get-ChildItem -LiteralPath $release -Filter '*.apk' -File).Count -eq 2) 'Se publicaron archivos después de un fallo.'
}
try {
    $release = Join-Path $fixture 'build/releases'
    $fixtureOutput = Join-Path $fixture 'build/app/outputs/flutter-apk/app-debug.apk'
    foreach ($folder in @('tool', 'android', 'build/releases', 'build/app/outputs/flutter-apk')) {
        [IO.Directory]::CreateDirectory((Join-Path $fixture $folder)) | Out-Null
    }
    $script = Join-Path $fixture 'tool/build_apk.ps1'
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'build_apk.ps1') -Destination $script
    Copy-Item -LiteralPath (Join-Path $projectRoot 'android/gradle.properties') -Destination (Join-Path $fixture 'android/gradle.properties')
    [IO.File]::WriteAllText((Join-Path $fixture 'pubspec.yaml'), $spec)
    New-Item -ItemType HardLink -Path $fixtureOutput -Target $source | Out-Null
    foreach ($name in @('anterior-a.apk', 'anterior-b.apk', 'conservar.txt')) {
        [IO.File]::WriteAllText((Join-Path $release $name), 'test')
    }
    $outside = Join-Path $fixture 'build/otro.apk'
    [IO.File]::WriteAllText($outside, 'no borrar')

    $failedFlutter = Join-Path $fixture 'tool/flutter failed.cmd'
    [IO.File]::WriteAllText($failedFlutter, "@echo off`r`nexit /b 9`r`n")
    $failed = $false
    try { & $script -FlutterExecutable $failedFlutter | Out-Null } catch { $failed = $true }
    Assert-True $failed 'Una compilación fallida debe impedir publicar.'
    Assert-Previous
    Write-Output 'OK: compilación fallida conserva versiones aunque exista un APK previo válido.'

    [IO.File]::WriteAllText((Join-Path $fixture 'pubspec.yaml'), 'version: 99.0.0+999')
    $failed = $false
    try { & $script -SkipBuild | Out-Null } catch { $failed = $true }
    Assert-True $failed 'Una versión incorrecta debe impedir publicar.'
    Assert-Previous
    [IO.File]::WriteAllText((Join-Path $fixture 'pubspec.yaml'), $spec)
    Write-Output 'OK: APK de otra versión conserva los anteriores.'

    # Se retira el enlace antes de crear el archivo corrupto: nunca se altera el APK real.
    Remove-Item -LiteralPath $fixtureOutput
    [IO.File]::WriteAllText($fixtureOutput, 'APK corrupto')
    $failed = $false
    try { & $script -SkipBuild | Out-Null } catch { $failed = $true }
    Assert-True $failed 'Un APK corrupto debe impedir publicar.'
    Assert-Previous
    Remove-Item -LiteralPath $fixtureOutput
    New-Item -ItemType HardLink -Path $fixtureOutput -Target $source | Out-Null
    Write-Output 'OK: APK corrupto conserva los anteriores.'

    $result = & $script -SkipBuild
    Assert-True ($result.Removed -eq 2) 'Deben eliminarse exactamente dos APK antiguos.'
    Assert-True ((Get-ChildItem -LiteralPath $release -Filter '*.apk' -File).Count -eq 1) 'Debe quedar un solo APK.'
    Assert-True ((Get-FileHash -LiteralPath $result.Apk).Hash -eq (Get-FileHash -LiteralPath $source).Hash) 'La copia entregable debe coincidir con el APK validado.'
    Assert-True (Test-Path -LiteralPath (Join-Path $release 'conservar.txt')) 'No se deben eliminar otros archivos.'
    Assert-True (Test-Path -LiteralPath $outside) 'No se deben borrar APK de otras carpetas.'
    Write-Output 'OK: publicación válida conserva solo el último y respeta otros archivos/carpetas.'

    $again = & $script -Mode Debug -SkipBuild
    Assert-True ($again.Removed -eq 0) 'Repetir la publicación no debe borrar el APK vigente.'
    Assert-True (Test-Path -LiteralPath $again.Apk) 'Debe conservarse el APK vigente.'
    Assert-True ($again.Apk.EndsWith('-debug.apk', [StringComparison]::Ordinal)) 'El nombre de entrega debe ser estable.'
    Write-Output 'OK: publicación repetida conserva la versión actual.'
    Write-Output '5 comprobaciones aprobadas.'
} finally {
    $absolute = [IO.Path]::GetFullPath($fixture)
    if (-not $absolute.StartsWith($baseFolder + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
        throw 'Temporal de pruebas fuera de la carpeta prevista.'
    }
    if (Test-Path -LiteralPath $absolute) { Remove-Item -LiteralPath $absolute -Recurse -Force }
}
