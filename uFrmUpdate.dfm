object frmUpdate: TfrmUpdate
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Atualiza'#231#227'o do Sistema - Ponto Control iD'
  ClientHeight = 470
  ClientWidth = 540
  Color = clWhite
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnClose = FormClose
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 15
  object pnlHeader: TPanel
    Left = 0
    Top = 0
    Width = 540
    Height = 76
    Align = alTop
    BevelOuter = bvNone
    Color = 2761244
    ParentBackground = False
    TabOrder = 0
    object imgLogo: TImage
      Left = 16
      Top = 12
      Width = 52
      Height = 52
      Proportional = True
      Stretch = True
    end
    object lblTitle: TLabel
      Left = 80
      Top = 14
      Width = 230
      Height = 25
      Caption = 'Atualiza'#231#227'o do Sistema'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -19
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblSubTitle: TLabel
      Left = 80
      Top = 44
      Width = 338
      Height = 15
      Caption =
        'Uma vers'#227'o mais recente com melhorias e corre'#231#245'es est'#225' dispon'#237 +
        'vel'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 16297272
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
  end
  object pnlContent: TPanel
    Left = 0
    Top = 76
    Width = 540
    Height = 334
    Align = alClient
    BevelOuter = bvNone
    Color = clWhite
    ParentBackground = False
    TabOrder = 1
    object lblNotas: TLabel
      Left = 20
      Top = 98
      Width = 134
      Height = 15
      Caption = 'Novidades e Altera'#231#245'es:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblProgresso: TLabel
      Left = 20
      Top = 296
      Width = 230
      Height = 15
      Caption = 'Pronto para iniciar download da atualiza'#231#227'o'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 4210752
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object lblPorcentagem: TLabel
      Left = 470
      Top = 296
      Width = 50
      Height = 15
      Alignment = taRightJustify
      AutoSize = False
      Caption = '0%'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 2761244
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object pnlCardAtual: TPanel
      Left = 20
      Top = 14
      Width = 240
      Height = 70
      BevelKind = bkFlat
      BevelOuter = bvNone
      Color = clWhite
      ParentBackground = False
      TabOrder = 0
      object lblAtualTitulo: TLabel
        Left = 15
        Top = 8
        Width = 94
        Height = 15
        Caption = 'Vers'#227'o Instalada'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clGray
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
      end
      object lblVersaoAtual: TLabel
        Left = 15
        Top = 24
        Width = 60
        Height = 25
        Caption = 'v1.0.1'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 2761244
        Font.Height = -19
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblBuildAtual: TLabel
        Left = 15
        Top = 48
        Width = 40
        Height = 15
        Caption = 'Build 0'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clGray
        Font.Height = -11
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
      end
    end
    object pnlCardNova: TPanel
      Left = 280
      Top = 14
      Width = 240
      Height = 70
      BevelKind = bkFlat
      BevelOuter = bvNone
      Color = clWhite
      ParentBackground = False
      TabOrder = 1
      object lblNovaTitulo: TLabel
        Left = 15
        Top = 8
        Width = 111
        Height = 15
        Caption = 'Nova Vers'#227'o no GitHub'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clGray
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
      end
      object lblVersaoNova: TLabel
        Left = 15
        Top = 24
        Width = 60
        Height = 25
        Caption = 'v1.0.2'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 1274643
        Font.Height = -19
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblBuildNova: TLabel
        Left = 15
        Top = 48
        Width = 40
        Height = 15
        Caption = 'Build 0'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clGray
        Font.Height = -11
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
      end
    end
    object memNotas: TMemo
      Left = 20
      Top = 120
      Width = 500
      Height = 130
      Color = 16382457
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 2761244
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      ReadOnly = True
      ScrollBars = ssVertical
      TabOrder = 2
    end
    object pbDownload: TProgressBar
      Left = 20
      Top = 264
      Width = 500
      Height = 22
      Smooth = True
      TabOrder = 3
    end
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 410
    Width = 540
    Height = 60
    Align = alBottom
    BevelOuter = bvNone
    Color = 16119285
    ParentBackground = False
    TabOrder = 2
    object btnBaixar: TButton
      Left = 250
      Top = 11
      Width = 165
      Height = 38
      Caption = 'Baixar e Atualizar'
      Default = True
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 0
      OnClick = btnBaixarClick
    end
    object btnCancelar: TButton
      Left = 425
      Top = 11
      Width = 95
      Height = 38
      Cancel = True
      Caption = 'Fechar'
      TabOrder = 1
      OnClick = btnCancelarClick
    end
  end
  object tmrAuto: TTimer
    Enabled = False
    OnTimer = tmrAutoTimer
    Left = 24
    Top = 424
  end
end
