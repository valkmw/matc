
# Iniciador MAS - PowerShell / SSH

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

# COLOQUE A URL RAW DO SEU CMD AQUI
$urlCmd = 'https://raw.githubusercontent.com/valkmw/matc/refs/heads/main/MAS_AIO.cmd'

# Opcional: hash SHA256 de uma versão aprovada
$sha256Esperado = ''

$arquivo = Join-Path $env:TEMP (
    'MAS_{0}.cmd' -f [guid]::NewGuid().ToString('N')
)

try {
    if ($urlCmd -match 'SEU_USUARIO') {
        throw 'Configure a URL RAW do MAS.'
    }

    # Evita reinicializacao por arquitetura incorreta
    if (-not [Environment]::Is64BitProcess) {
        throw 'Use PowerShell de 64 bits.'
    }

    # Evita a tentativa de abrir uma janela UAC
    & "$env:WINDIR\System32\fltmc.exe" *> $null

    if ($LASTEXITCODE -ne 0) {
        throw 'A sessao precisa de privilegios administrativos.'
    }

    Write-Output 'Baixando MAS do GitHub...'

    Invoke-WebRequest `
        -Uri $urlCmd `
        -OutFile $arquivo `
        -UseBasicParsing

    if (-not (Test-Path -LiteralPath $arquivo)) {
        throw 'Arquivo nao encontrado apos o download.'
    }

    $tamanho = (Get-Item $arquivo).Length

    if ($tamanho -lt 100000) {
        throw 'Arquivo inesperadamente pequeno. Verifique a URL.'
    }

    $hash = (Get-FileHash $arquivo -Algorithm SHA256).Hash

    Write-Output "Arquivo recebido: $tamanho bytes"
    Write-Output "SHA256: $hash"

    if ($sha256Esperado) {
        if ($hash -ne $sha256Esperado.Trim()) {
            throw 'Hash diferente do esperado. Execucao cancelada.'
        }
    }
    else {
        Write-Output 'Aviso: hash ainda nao validado.'
    }

    Write-Output ''
    Write-Output 'Iniciando MAS no terminal atual...'
    Write-Output '----------------------------------------'

    # Executa diretamente, sem Start-Process
    # /HWID = modo automatico
    # -qedit = pula a rotina QuickEdit
    # Sem /S para nao ocultar as mensagens

    & $arquivo /HWID -qedit

    $codigo = $LASTEXITCODE

    Write-Output '----------------------------------------'
    Write-Output "Processo encerrado. Codigo: $codigo"

    # Verificacao independente da ativacao
    Write-Output 'Verificando ativacao do Windows...'

    & cscript.exe //NoLogo "$env:WINDIR\System32\slmgr.vbs" /xpr

}
catch {
    Write-Error "Erro: $($_.Exception.Message)"
}
finally {
    if (Test-Path -LiteralPath $arquivo) {
        Remove-Item $arquivo -Force -ErrorAction SilentlyContinue
    }
}
