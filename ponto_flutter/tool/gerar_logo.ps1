# Gera a logo do Go Up Ponto (PNG em alta resolução + ICO multi-tamanho para o Windows).
# Uso: powershell -ExecutionPolicy Bypass -File tool\gerar_logo.ps1
Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = 'Stop'
$raiz = Split-Path -Parent $PSScriptRoot

function Novo-Caminho-Arredondado([float]$x, [float]$y, [float]$w, [float]$h, [float]$r) {
  $p = New-Object System.Drawing.Drawing2D.GraphicsPath
  $d = $r * 2
  $p.AddArc($x, $y, $d, $d, 180, 90)
  $p.AddArc($x + $w - $d, $y, $d, $d, 270, 90)
  $p.AddArc($x + $w - $d, $y + $h - $d, $d, $d, 0, 90)
  $p.AddArc($x, $y + $h - $d, $d, $d, 90, 90)
  $p.CloseFigure()
  return $p
}

function Desenhar-Logo([int]$S) {
  $bmp = New-Object System.Drawing.Bitmap $S, $S, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = 'AntiAlias'
  $g.PixelOffsetMode = 'HighQuality'
  $g.Clear([System.Drawing.Color]::Transparent)
  $f = $S / 1024.0

  # Fundo: quadrado arredondado com degradê azul -> ciano
  $fundo = Novo-Caminho-Arredondado (24*$f) (24*$f) (976*$f) (976*$f) (220*$f)
  $grad = New-Object System.Drawing.Drawing2D.LinearGradientBrush (New-Object System.Drawing.PointF 0, 0), (New-Object System.Drawing.PointF $S, $S), ([System.Drawing.Color]::FromArgb(255, 30, 58, 138)), ([System.Drawing.Color]::FromArgb(255, 6, 182, 212))
  $blend = New-Object System.Drawing.Drawing2D.ColorBlend 3
  $blend.Colors = @([System.Drawing.Color]::FromArgb(255, 30, 58, 138), [System.Drawing.Color]::FromArgb(255, 37, 99, 235), [System.Drawing.Color]::FromArgb(255, 6, 182, 212))
  $blend.Positions = @([single]0, [single]0.55, [single]1)
  $grad.InterpolationColors = $blend
  $g.FillPath($grad, $fundo)

  # Brilho suave no topo
  $brilho = Novo-Caminho-Arredondado (24*$f) (24*$f) (976*$f) (430*$f) (220*$f)
  $gb = New-Object System.Drawing.Drawing2D.LinearGradientBrush (New-Object System.Drawing.PointF 0, (24*$f)), (New-Object System.Drawing.PointF 0, (454*$f)), ([System.Drawing.Color]::FromArgb(60, 255, 255, 255)), ([System.Drawing.Color]::FromArgb(0, 255, 255, 255))
  $g.FillPath($gb, $brilho)

  $branco = [System.Drawing.Color]::White
  $cx = 512*$f; $cy = 560*$f; $r = 300*$f

  # Mostrador do relógio (anel aberto no topo, por onde a seta "sobe")
  $anel = New-Object System.Drawing.Pen $branco, (64*$f)
  $anel.StartCap = 'Round'; $anel.EndCap = 'Round'
  $g.DrawArc($anel, ($cx - $r), ($cy - $r), (2*$r), (2*$r), -58, 296)

  # Marcadores das horas 3, 6 e 9
  $marca = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(235, 255, 255, 255))
  foreach ($ang in @(0, 90, 180)) {
    $rad = $ang * [Math]::PI / 180
    $mx = $cx + [Math]::Cos($rad) * ($r - 92*$f); $my = $cy + [Math]::Sin($rad) * ($r - 92*$f)
    $g.FillEllipse($marca, ($mx - 22*$f), ($my - 22*$f), (44*$f), (44*$f))
  }

  # Ponteiro das horas (para a direita, levemente para cima)
  $ponteiro = New-Object System.Drawing.Pen $branco, (58*$f)
  $ponteiro.StartCap = 'Round'; $ponteiro.EndCap = 'Round'
  $g.DrawLine($ponteiro, $cx, $cy, ($cx + 150*$f), ($cy + 70*$f))

  # Ponteiro dos minutos = seta "Go Up" atravessando a abertura do anel
  $seta = New-Object System.Drawing.Pen $branco, (64*$f)
  $seta.StartCap = 'Round'; $seta.EndCap = 'Flat'
  $topoHaste = 250*$f
  $g.DrawLine($seta, $cx, $cy, $cx, $topoHaste)
  $ponta = New-Object System.Drawing.Drawing2D.GraphicsPath
  $ponta.AddPolygon(@(
      (New-Object System.Drawing.PointF $cx, (108*$f)),
      (New-Object System.Drawing.PointF ($cx + 128*$f), (282*$f)),
      (New-Object System.Drawing.PointF ($cx - 128*$f), (282*$f))))
  $g.FillPath((New-Object System.Drawing.SolidBrush $branco), $ponta)

  # Centro
  $g.FillEllipse((New-Object System.Drawing.SolidBrush $branco), ($cx - 56*$f), ($cy - 56*$f), (112*$f), (112*$f))
  $g.FillEllipse((New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 37, 99, 235))), ($cx - 24*$f), ($cy - 24*$f), (48*$f), (48*$f))

  $g.Dispose()
  return $bmp
}

function Salvar-Png($bmp, $arquivo) {
  New-Item -ItemType Directory -Force (Split-Path -Parent $arquivo) | Out-Null
  $bmp.Save($arquivo, [System.Drawing.Imaging.ImageFormat]::Png)
}

# PNG para o aplicativo (canto superior e telas)
$logo = Desenhar-Logo 1024
Salvar-Png $logo (Join-Path $raiz 'assets\logo.png')
$logo.Dispose()

# ICO com várias resoluções (PNG embutido em cada entrada)
$tamanhos = @(16, 24, 32, 48, 64, 128, 256)
$imagens = foreach ($t in $tamanhos) {
  $b = Desenhar-Logo $t
  $ms = New-Object System.IO.MemoryStream
  $b.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
  $b.Dispose()
  , $ms.ToArray()
}
$ico = Join-Path $raiz 'windows\runner\resources\app_icon.ico'
$fs = [System.IO.File]::Create($ico)
$w = New-Object System.IO.BinaryWriter $fs
$w.Write([uint16]0); $w.Write([uint16]1); $w.Write([uint16]$tamanhos.Count)
$offset = 6 + 16 * $tamanhos.Count
for ($i = 0; $i -lt $tamanhos.Count; $i++) {
  $t = $tamanhos[$i]
  $lado = if ($t -ge 256) { 0 } else { $t }
  $w.Write([byte]$lado); $w.Write([byte]$lado); $w.Write([byte]0); $w.Write([byte]0)
  $w.Write([uint16]1); $w.Write([uint16]32)
  $w.Write([uint32]$imagens[$i].Length); $w.Write([uint32]$offset)
  $offset += $imagens[$i].Length
}
foreach ($img in $imagens) { $w.Write($img) }
$w.Close()
Write-Output "Logo gerada: assets\logo.png e windows\runner\resources\app_icon.ico"
