object frmUpdate: TfrmUpdate
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Atualiza'#231#227'o do Sistema - Ponto Control iD'
  ClientHeight = 440
  ClientWidth = 520
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
    Width = 520
    Height = 70
    Align = alTop
    BevelOuter = bvNone
    Color = 2761244
    ParentBackground = False
    TabOrder = 0
    object lblTitle: TLabel
      Left = 20
      Top = 14
      Width = 230
      Height = 21
      Caption = 'Atualiza'#231#227'o do Sistema Control iD'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -16
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblSubTitle: TLabel
      Left = 20
      Top = 38
      Width = 338
      Height = 15
      Caption = 'Uma vers'#227'o mais recente com melhorias e corre'#231#245'es est'#225' dispon'#237'vel'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 14211288
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
  end
  object pnlContent: TPanel
    Left = 0
    Top = 70
    Width = 520
    Height = 310
    Align = alClient
    BevelOuter = bvNone
    Color = clWhite
    ParentBackground = False
    TabOrder = 1
    object lblVersaoAtual: TLabel
      Left = 25
      Top = 15
      Width = 135
      Height = 17
      Caption = 'Vers'#227'o Instalada: v1.0.0'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 5592405
      Font.Height = -13
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblVersaoNova: TLabel
      Left = 260
      Top = 15
      Width = 145
      Height = 17
      Caption = 'Nova Vers'#227'o: v1.0.1'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 1274643
      Font.Height = -13
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblNotas: TLabel
      Left = 25
      Top = 45
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
    object memNotas: TMemo
      Left = 25
      Top = 68
      Width = 470
      Height = 155
      Color = 16382457
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 2761244
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      ReadOnly = True
      ScrollBars = ssVertical
      TabOrder = 0
    end
    object pbDownload: TProgressBar
      Left = 25
      Top = 238
      Width = 470
      Height = 22
      Smooth = True
      TabOrder = 1
    end
    object lblProgresso: TLabel
      Left = 25
      Top = 268
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
      Left = 445
      Top = 268
      Width = 50
      Height = 15
      Alignment = taRightJustify
      Caption = '0%'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 2761244
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 380
    Width = 520
    Height = 60
    Align = alBottom
    BevelOuter = bvNone
    Color = 16119285
    ParentBackground = False
    TabOrder = 2
    object btnBaixar: TButton
      Left = 230
      Top = 12
      Width = 160
      Height = 36
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
      Left = 400
      Top = 12
      Width = 95
      Height = 36
      Cancel = True
      Caption = 'Fechar'
      TabOrder = 1
      OnClick = btnCancelarClick
    end
  end
end
