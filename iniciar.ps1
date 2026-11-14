
# ============================================
# INICIADOR MAS - POWERSHELL / SSH
# ============================================

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

# URL RAW do arquivo CMD no GitHub
$urlCmd = 'https://raw.githubusercontent.com/valkmw/matc/refs/heads/main/MAS_AIO.cmd'

# Hash SHA256 opcional de uma versao verificada
$sha256Esperado = ''

# Arquivo temporario
$arquivo = Join-Path $env:TEMP (
    'MAS_{0}.cmd' -f [guid]::NewGuid().ToString('N')
)

try {

    # Verificar URL
    if ($urlCmd -match 'SEU_USUARIO') {
        throw 'Configure a URL RAW do MAS.'
    }

    # Verificar arquitetura do PowerShell
    if (-not [Environment]::Is64BitProcess) {
        throw 'Utilize o PowerShell de 64 bits.'
    }

    # Verificar permissoes administrativas
    & "$env:WINDIR\System32\fltmc.exe" *> $null

    if ($LASTEXITCODE -ne 0) {
        throw 'Execute em uma sessao com privilegios administrativos.'
    }

    Write-Output ''
    Write-Output '======================================'
    Write-Output '  INICIADOR MICROSOFT ACTIVATION SCRIPTS'
    Write-Output '======================================'
    Write-Output ''

    # Baixar arquivo CMD
    Write-Output 'Baixando MAS do GitHub...'

    Invoke-WebRequest `
        -Uri $urlCmd `
        -OutFile $arquivo `
        -UseBasicParsing

    # Verificar download
    if (-not (Test-Path -LiteralPath $arquivo)) {
        throw 'Falha ao baixar o arquivo CMD.'
    }

    $tamanho = (Get-Item $arquivo).Length

    if ($tamanho -lt 100000) {
        throw 'Arquivo inesperadamente pequeno. Verifique a URL.'
    }

    Write-Output 'Download concluido.'

    # Verificar integridade
    $hash = (Get-FileHash $arquivo -Algorithm SHA256).Hash

    Write-Output "SHA256: $hash"

    if ($sha256Esperado) {
        if ($hash -ne $sha256Esperado.Trim()) {
            throw 'Hash diferente do esperado.'
        }
    }
    else {
        Write-Output 'Aviso: hash nao validado.'
    }

    Write-Output ''
    Write-Output 'Abrindo menu principal do MAS...'
    Write-Output ''

    # ========================================
    # EXECUTAR MAS SEM ATIVACAO AUTOMATICA
    # ========================================

    # -qedit evita a rotina de reinicializacao
    # do console para configurar QuickEdit.
    #
    # Nenhum metodo de ativacao e selecionado.

    & $arquivo -qedit

    $codigo = $LASTEXITCODE

    Write-Output ''
    Write-Output '======================================'
    Write-Output "MAS encerrado. Codigo: $codigo"
    Write-Output '======================================'

}
catch {
    Write-Error "Erro: $($_.Exception.Message)"
}
finally {

    # Remover arquivo temporario
    if (Test-Path -LiteralPath $arquivo) {
        Remove-Item `
            -LiteralPath $arquivo `
            -Force `
            -ErrorAction SilentlyContinue
    }

}
