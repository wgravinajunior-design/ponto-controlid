object frmMain: TfrmMain
  Left = 0
  Top = 0
  Caption = 
    'Control iD - Integrador de Ponto Eletr'#244'nico (iDClass / iDFace / ' +
    'iDAccess)'
  ClientHeight = 720
  ClientWidth = 1100
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  WindowState = wsMaximized
  OnClose = FormClose
  OnCreate = FormCreate
  OnResize = FormResize
  OnShow = FormShow
  TextHeight = 15
  object pnlTop: TPanel
    Left = 0
    Top = 0
    Width = 1100
    Height = 85
    Align = alTop
    BevelOuter = bvNone
    Color = 2761244
    ParentBackground = False
    TabOrder = 0
    object lblTitle: TLabel
      Left = 20
      Top = 28
      Width = 164
      Height = 25
      Caption = 'Controle de Ponto'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -19
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object btnTopConfig: TButton
      Left = 200
      Top = 20
      Width = 145
      Height = 42
      Caption = 'Configura'#231#245'es'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 1
      OnClick = btnTopConfigClick
    end
    object btnTopUpdate: TButton
      Left = 355
      Top = 20
      Width = 230
      Height = 42
      Caption = 'Atualiza'#231#227'o Dispon'#237'vel'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 2
      Visible = False
      OnClick = btnTopUpdateClick
    end
    object pnlQuickActions: TPanel
      Left = 420
      Top = 0
      Width = 680
      Height = 85
      Align = alRight
      BevelOuter = bvNone
      Color = 2761244
      ParentBackground = False
      TabOrder = 0
      object btnQuickTest: TButton
        Left = 5
        Top = 10
        Width = 125
        Height = 35
        Caption = 'Testar Conex'#227'o'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 0
        OnClick = btnQuickTestClick
      end
      object btnQuickSyncTime: TButton
        Left = 135
        Top = 10
        Width = 125
        Height = 35
        Caption = 'Sincronizar'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 1
        OnClick = btnQuickSyncTimeClick
      end
      object btnQuickCollect: TButton
        Left = 265
        Top = 10
        Width = 120
        Height = 35
        Caption = 'Coletar'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 2
        OnClick = btnQuickCollectClick
      end
      object btnQuickAuto: TButton
        Left = 390
        Top = 10
        Width = 138
        Height = 35
        Caption = 'Auto: OFF'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 3
        OnClick = btnQuickAutoClick
      end
    end
  end
  object pgcMain: TPageControl
    Left = 0
    Top = 85
    Width = 1100
    Height = 610
    ActivePage = tabDashboard
    Align = alClient
    TabOrder = 1
    OnChange = pgcMainChange
    object tabDashboard: TTabSheet
      Caption = '  Painel de Monitoramento  '
      object pnlCards: TPanel
        Left = 0
        Top = 0
        Width = 1092
        Height = 90
        Align = alTop
        BevelOuter = bvNone
        Color = 15724527
        ParentBackground = False
        TabOrder = 0
        object pnlCard1: TPanel
          Left = 15
          Top = 10
          Width = 240
          Height = 70
          BevelKind = bkFlat
          BevelOuter = bvNone
          Color = clWhite
          ParentBackground = False
          TabOrder = 0
          object lblCard1Title: TLabel
            Left = 15
            Top = 10
            Width = 113
            Height = 15
            Caption = 'Rel'#243'gios Cadastrados'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clGray
            Font.Height = -12
            Font.Name = 'Segoe UI'
            Font.Style = []
            ParentFont = False
          end
          object lblCard1Val: TLabel
            Left = 15
            Top = 28
            Width = 12
            Height = 28
            Caption = '0'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = 2761244
            Font.Height = -20
            Font.Name = 'Segoe UI'
            Font.Style = [fsBold]
            ParentFont = False
          end
        end
        object pnlCard2: TPanel
          Left = 275
          Top = 10
          Width = 240
          Height = 70
          BevelKind = bkFlat
          BevelOuter = bvNone
          Color = clWhite
          ParentBackground = False
          TabOrder = 1
          object lblCard2Title: TLabel
            Left = 15
            Top = 10
            Width = 66
            Height = 15
            Caption = 'Batidas Hoje'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clGray
            Font.Height = -12
            Font.Name = 'Segoe UI'
            Font.Style = []
            ParentFont = False
          end
          object lblCard2Val: TLabel
            Left = 15
            Top = 28
            Width = 12
            Height = 28
            Caption = '0'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clGreen
            Font.Height = -20
            Font.Name = 'Segoe UI'
            Font.Style = [fsBold]
            ParentFont = False
          end
        end
        object pnlCard3: TPanel
          Left = 535
          Top = 10
          Width = 240
          Height = 70
          BevelKind = bkFlat
          BevelOuter = bvNone
          Color = clWhite
          ParentBackground = False
          TabOrder = 2
          object lblCard3Title: TLabel
            Left = 15
            Top = 10
            Width = 106
            Height = 15
            Caption = 'Total Colaboradores'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clGray
            Font.Height = -12
            Font.Name = 'Segoe UI'
            Font.Style = []
            ParentFont = False
          end
          object lblCard3Val: TLabel
            Left = 15
            Top = 28
            Width = 12
            Height = 28
            Caption = '0'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = 12543503
            Font.Height = -20
            Font.Name = 'Segoe UI'
            Font.Style = [fsBold]
            ParentFont = False
          end
        end
        object pnlCard4: TPanel
          Left = 795
          Top = 10
          Width = 280
          Height = 70
          BevelKind = bkFlat
          BevelOuter = bvNone
          Color = clWhite
          ParentBackground = False
          TabOrder = 3
          object lblCard4Title: TLabel
            Left = 15
            Top = 10
            Width = 72
            Height = 15
            Caption = #218'ltima Coleta'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clGray
            Font.Height = -12
            Font.Name = 'Segoe UI'
            Font.Style = []
            ParentFont = False
          end
          object lblCard4Val: TLabel
            Left = 15
            Top = 28
            Width = 131
            Height = 28
            Caption = 'N'#227'o realizada'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = 4210752
            Font.Height = -20
            Font.Name = 'Segoe UI'
            Font.Style = [fsBold]
            ParentFont = False
          end
        end
      end
      object pnlLogHeader: TPanel
        Left = 0
        Top = 90
        Width = 1092
        Height = 40
        Align = alTop
        BevelOuter = bvNone
        Color = 15132390
        ParentBackground = False
        TabOrder = 1
        DesignSize = (
          1092
          40)
        object lblLogTitle: TLabel
          Left = 15
          Top = 11
          Width = 210
          Height = 17
          Caption = 'Log de Atividades em Tempo Real'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = 3355443
          Font.Height = -13
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object btnClearLog: TButton
          Left = 880
          Top = 6
          Width = 98
          Height = 28
          Anchors = [akTop, akRight]
          Caption = 'Limpar Log'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
          TabOrder = 0
          OnClick = btnClearLogClick
        end
        object btnSaveLog: TButton
          Left = 984
          Top = 6
          Width = 98
          Height = 28
          Anchors = [akTop, akRight]
          Caption = 'Salvar Log'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
          TabOrder = 1
          OnClick = btnSaveLogClick
        end
      end
      object mmoLog: TMemo
        Left = 0
        Top = 130
        Width = 1092
        Height = 450
        Align = alClient
        Color = 2105376
        Font.Charset = ANSI_CHARSET
        Font.Color = 15132390
        Font.Height = -13
        Font.Name = 'Consolas'
        Font.Style = []
        ParentFont = False
        ReadOnly = True
        ScrollBars = ssVertical
        TabOrder = 2
      end
    end
    object tabRelogios: TTabSheet
      Caption = '  Rel'#243'gios de Ponto  '
      ImageIndex = 1
      object splRelogio: TSplitter
        Left = 622
        Top = 0
        Height = 580
        Align = alRight
        ExplicitLeft = 600
      end
      object pnlRelogiosGrid: TPanel
        Left = 0
        Top = 0
        Width = 622
        Height = 580
        Align = alClient
        BevelOuter = bvNone
        TabOrder = 0
        object dbgRelogios: TDBGrid
          Left = 0
          Top = 45
          Width = 622
          Height = 535
          Align = alClient
          Options = [dgTitles, dgIndicator, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgRowSelect, dgAlwaysShowSelection, dgConfirmDelete, dgCancelOnExit]
          ReadOnly = True
          TabOrder = 0
          TitleFont.Charset = DEFAULT_CHARSET
          TitleFont.Color = clWindowText
          TitleFont.Height = -12
          TitleFont.Name = 'Segoe UI'
          TitleFont.Style = []
          OnCellClick = dbgRelogiosCellClick
          OnDrawColumnCell = dbgGridDrawColumnCell
        end
        object pnlRelogiosTop: TPanel
          Left = 0
          Top = 0
          Width = 622
          Height = 45
          Align = alTop
          BevelOuter = bvNone
          Color = 15724527
          ParentBackground = False
          TabOrder = 1
          object btnNovoRelogio: TButton
            Left = 10
            Top = 8
            Width = 135
            Height = 30
            Caption = 'Novo Rel'#243'gio'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -12
            Font.Name = 'Segoe UI'
            Font.Style = [fsBold]
            ParentFont = False
            TabOrder = 0
            OnClick = btnNovoRelogioClick
          end
          object btnAtualizarRelogios: TButton
            Left = 155
            Top = 8
            Width = 110
            Height = 30
            Caption = 'Atualizar'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -12
            Font.Name = 'Segoe UI'
            Font.Style = [fsBold]
            ParentFont = False
            TabOrder = 1
            OnClick = btnAtualizarRelogiosClick
          end
        end
      end
      object pnlRelogioForm: TPanel
        Left = 625
        Top = 0
        Width = 467
        Height = 580
        Align = alRight
        BevelOuter = bvNone
        Color = clWhitesmoke
        ParentBackground = False
        TabOrder = 1
        object lblFormTitle: TLabel
          Left = 20
          Top = 15
          Width = 145
          Height = 17
          Caption = 'Dados do Equipamento'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = 2761244
          Font.Height = -13
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object lblRelNome: TLabel
          Left = 20
          Top = 45
          Width = 101
          Height = 15
          Caption = 'Nome do Rel'#243'gio *'
        end
        object lblRelIP: TLabel
          Left = 20
          Top = 100
          Width = 70
          Height = 15
          Caption = 'Endere'#231'o IP *'
        end
        object lblRelPorta: TLabel
          Left = 270
          Top = 100
          Width = 36
          Height = 15
          Caption = 'Porta *'
        end
        object lblRelUser: TLabel
          Left = 20
          Top = 155
          Width = 48
          Height = 15
          Caption = 'Usu'#225'rio *'
        end
        object lblRelSenha: TLabel
          Left = 240
          Top = 155
          Width = 40
          Height = 15
          Caption = 'Senha *'
        end
        object lblRelModelo: TLabel
          Left = 20
          Top = 210
          Width = 49
          Height = 15
          Caption = 'Modelo *'
        end
        object lblRelModoColeta: TLabel
          Left = 240
          Top = 210
          Width = 85
          Height = 15
          Caption = 'Modo de Coleta'
        end
        object edtRelNome: TEdit
          Left = 20
          Top = 65
          Width = 425
          Height = 23
          TabOrder = 0
        end
        object edtRelIP: TEdit
          Left = 20
          Top = 120
          Width = 230
          Height = 23
          TabOrder = 1
          Text = '192.168.1.200'
        end
        object edtRelPorta: TEdit
          Left = 270
          Top = 120
          Width = 80
          Height = 23
          TabOrder = 2
          Text = '80'
        end
        object chkRelSSL: TCheckBox
          Left = 365
          Top = 122
          Width = 80
          Height = 19
          Caption = 'HTTPS (SSL)'
          TabOrder = 3
        end
        object edtRelUser: TEdit
          Left = 20
          Top = 175
          Width = 200
          Height = 23
          TabOrder = 4
          Text = 'admin'
        end
        object edtRelSenha: TEdit
          Left = 240
          Top = 175
          Width = 205
          Height = 23
          PasswordChar = '*'
          TabOrder = 5
          Text = 'admin'
        end
        object cmbRelModelo: TComboBox
          Left = 20
          Top = 230
          Width = 200
          Height = 23
          Style = csDropDownList
          ItemIndex = 0
          TabOrder = 6
          Text = 'IDCLASS (REP de Ponto)'
          Items.Strings = (
            'IDCLASS (REP de Ponto)'
            'IDFACE (Facial)'
            'IDACCESS (Acesso)'
            'IDBLOCK (Catraca)'
            'OUTRO')
        end
        object cmbRelModoColeta: TComboBox
          Left = 240
          Top = 230
          Width = 205
          Height = 23
          Style = csDropDownList
          ItemIndex = 0
          TabOrder = 7
          Text = 'API (access_logs)'
          Items.Strings = (
            'API (access_logs)'
            'AFD_671 (Portaria 671)'
            'AFD_1510 (Portaria 1510)')
        end
        object chkRelAtivo: TCheckBox
          Left = 20
          Top = 270
          Width = 150
          Height = 19
          Caption = 'Equipamento Ativo'
          Checked = True
          State = cbChecked
          TabOrder = 8
        end
        object grpInfoHardware: TGroupBox
          Left = 20
          Top = 300
          Width = 425
          Height = 160
          Caption = ' Informa'#231#245'es Lidas do Equipamento '
          TabOrder = 9
          object lblSerial: TLabel
            Left = 15
            Top = 30
            Width = 91
            Height = 15
            Caption = 'N'#250'mero de S'#233'rie:'
          end
          object lblFW: TLabel
            Left = 15
            Top = 65
            Width = 106
            Height = 15
            Caption = 'Vers'#227'o do Firmware:'
          end
          object lblUltimoLog: TLabel
            Left = 15
            Top = 100
            Width = 95
            Height = 15
            Caption = #218'ltimo Log / NSR:'
          end
          object edtSerial: TEdit
            Left = 125
            Top = 27
            Width = 280
            Height = 23
            Color = clBtnFace
            ReadOnly = True
            TabOrder = 0
          end
          object edtFW: TEdit
            Left = 125
            Top = 62
            Width = 280
            Height = 23
            Color = clBtnFace
            ReadOnly = True
            TabOrder = 1
          end
          object edtUltimoLog: TEdit
            Left = 125
            Top = 97
            Width = 280
            Height = 23
            Color = clBtnFace
            ReadOnly = True
            TabOrder = 2
          end
        end
        object pnlRelogioBtns: TPanel
          Left = 20
          Top = 475
          Width = 425
          Height = 85
          BevelOuter = bvNone
          TabOrder = 10
          object btnSalvarRelogio: TButton
            Left = 0
            Top = 5
            Width = 135
            Height = 35
            Caption = 'Salvar'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -12
            Font.Name = 'Segoe UI'
            Font.Style = [fsBold]
            ParentFont = False
            TabOrder = 0
            OnClick = btnSalvarRelogioClick
          end
          object btnExcluirRelogio: TButton
            Left = 145
            Top = 5
            Width = 110
            Height = 35
            Caption = 'Excluir'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -12
            Font.Name = 'Segoe UI'
            Font.Style = [fsBold]
            ParentFont = False
            TabOrder = 1
            OnClick = btnExcluirRelogioClick
          end
          object btnTestarEsteRelogio: TButton
            Left = 265
            Top = 5
            Width = 160
            Height = 35
            Caption = 'Testar Conex'#227'o'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -12
            Font.Name = 'Segoe UI'
            Font.Style = [fsBold]
            ParentFont = False
            TabOrder = 2
            OnClick = btnTestarEsteRelogioClick
          end
          object btnSincHoraEste: TButton
            Left = 0
            Top = 45
            Width = 175
            Height = 35
            Caption = 'Sincronizar Hora'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -12
            Font.Name = 'Segoe UI'
            Font.Style = [fsBold]
            ParentFont = False
            TabOrder = 3
            OnClick = btnSincHoraEsteClick
          end
          object btnColetarEste: TButton
            Left = 185
            Top = 45
            Width = 175
            Height = 35
            Caption = 'Coletar Marca'#231#245'es'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -12
            Font.Name = 'Segoe UI'
            Font.Style = [fsBold]
            ParentFont = False
            TabOrder = 4
            OnClick = btnColetarEsteClick
          end
        end
      end
    end
    object tabColaboradores: TTabSheet
      Caption = '  Colaboradores  '
      ImageIndex = 2
      object splColaborador: TSplitter
        Left = 600
        Top = 0
        Height = 580
        Align = alRight
      end
      object pnlColaboradoresGrid: TPanel
        Left = 0
        Top = 0
        Width = 600
        Height = 580
        Align = alClient
        BevelOuter = bvNone
        TabOrder = 0
        object pnlColabTop: TPanel
          Left = 0
          Top = 0
          Width = 600
          Height = 55
          Align = alTop
          BevelOuter = bvNone
          Color = 15724527
          ParentBackground = False
          TabOrder = 0
          object lblBuscaColab: TLabel
            Left = 15
            Top = 18
            Width = 53
            Height = 15
            Caption = 'Pesquisar:'
          end
          object edtBuscaColab: TEdit
            Left = 75
            Top = 15
            Width = 145
            Height = 23
            TabOrder = 0
            OnChange = edtBuscaColabChange
          end
          object btnAtualizarColab: TButton
            Left = 230
            Top = 12
            Width = 100
            Height = 30
            Caption = 'Atualizar'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -12
            Font.Name = 'Segoe UI'
            Font.Style = [fsBold]
            ParentFont = False
            TabOrder = 1
            OnClick = btnAtualizarColabClick
          end
          object btnEnviarTodosPendentes: TButton
            Left = 340
            Top = 12
            Width = 130
            Height = 30
            Caption = 'Enviar Pendentes'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -12
            Font.Name = 'Segoe UI'
            Font.Style = [fsBold]
            ParentFont = False
            TabOrder = 2
            OnClick = btnEnviarTodosPendentesClick
          end
          object btnImportarDoRelogio: TButton
            Left = 480
            Top = 12
            Width = 110
            Height = 30
            Caption = 'No Rel'#243'gio'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -12
            Font.Name = 'Segoe UI'
            Font.Style = [fsBold]
            ParentFont = False
            TabOrder = 3
            OnClick = btnImportarDoRelogioClick
          end
          object btnLimparTodosRelogio: TButton
            Left = 600
            Top = 12
            Width = 140
            Height = 30
            Caption = 'Limpar Rel'#243'gio'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -12
            Font.Name = 'Segoe UI'
            Font.Style = [fsBold]
            ParentFont = False
            TabOrder = 6
            OnClick = btnLimparTodosRelogioClick
          end
          object btnEnviarColabRelogio: TButton
            Left = 595
            Top = 12
            Width = 0
            Height = 0
            TabOrder = 4
            Visible = False
            OnClick = btnEnviarColabRelogioClick
          end
          object btnRemoverColabRelogio: TButton
            Left = 595
            Top = 12
            Width = 0
            Height = 0
            TabOrder = 5
            Visible = False
            OnClick = btnRemoverColabRelogioClick
          end
        end
        object dbgColaboradores: TDBGrid
          Left = 0
          Top = 55
          Width = 600
          Height = 525
          Align = alClient
          Options = [dgTitles, dgIndicator, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgRowSelect, dgAlwaysShowSelection, dgConfirmDelete, dgCancelOnExit]
          ReadOnly = True
          TabOrder = 1
          TitleFont.Charset = DEFAULT_CHARSET
          TitleFont.Color = clWindowText
          TitleFont.Height = -12
          TitleFont.Name = 'Segoe UI'
          TitleFont.Style = []
          OnCellClick = dbgColaboradoresCellClick
          OnDrawColumnCell = dbgGridDrawColumnCell
        end
      end
      object pnlColaboradorForm: TPanel
        Left = 605
        Top = 0
        Width = 487
        Height = 580
        Align = alRight
        BevelOuter = bvNone
        Color = clWhitesmoke
        ParentBackground = False
        TabOrder = 1
        object lblColabFormTitle: TLabel
          Left = 20
          Top = 12
          Width = 139
          Height = 17
          Caption = 'Dados do Colaborador'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = 2761244
          Font.Height = -13
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object lblColabNome: TLabel
          Left = 20
          Top = 38
          Width = 127
          Height = 15
          Caption = 'Nome do Colaborador *'
        end
        object lblColabCPF: TLabel
          Left = 20
          Top = 85
          Width = 29
          Height = 15
          Caption = 'CPF *'
        end
        object lblColabPIS: TLabel
          Left = 170
          Top = 85
          Width = 60
          Height = 15
          Caption = 'PIS / PASEP'
        end
        object lblColabMatricula: TLabel
          Left = 320
          Top = 85
          Width = 58
          Height = 15
          Caption = 'Matr'#237'cula *'
        end
        object lblColabFuncao: TLabel
          Left = 20
          Top = 132
          Width = 82
          Height = 15
          Caption = 'Fun'#231#227'o / Cargo'
        end
        object lblColabCodigo: TLabel
          Left = 250
          Top = 132
          Width = 100
          Height = 15
          Caption = 'C'#243'digo no Teclado'
        end
        object lblColabSenha: TLabel
          Left = 360
          Top = 132
          Width = 67
          Height = 15
          Caption = 'Senha Ponto'
        end
        object lblColabRFID: TLabel
          Left = 20
          Top = 179
          Width = 139
          Height = 15
          Caption = 'Cart'#227'o RFID / Proximidade'
        end
        object lblColabBarras: TLabel
          Left = 250
          Top = 179
          Width = 138
          Height = 15
          Caption = 'C'#243'digo de Barras (Crach'#225')'
        end
        object lblColabHorario: TLabel
          Left = 20
          Top = 225
          Width = 157
          Height = 15
          Caption = 'Jornada / Hor'#225'rio de Trabalho'
        end
        object edtColabNome: TEdit
          Left = 20
          Top = 56
          Width = 445
          Height = 23
          TabOrder = 0
        end
        object edtColabCPF: TEdit
          Left = 20
          Top = 103
          Width = 140
          Height = 23
          TabOrder = 1
        end
        object edtColabPIS: TEdit
          Left = 170
          Top = 103
          Width = 140
          Height = 23
          TabOrder = 2
        end
        object edtColabMatricula: TEdit
          Left = 320
          Top = 103
          Width = 145
          Height = 23
          TabOrder = 3
        end
        object edtColabFuncao: TEdit
          Left = 20
          Top = 150
          Width = 220
          Height = 23
          TabOrder = 4
        end
        object edtColabCodigo: TEdit
          Left = 250
          Top = 150
          Width = 100
          Height = 23
          TabOrder = 5
        end
        object edtColabSenha: TEdit
          Left = 360
          Top = 150
          Width = 105
          Height = 23
          PasswordChar = '*'
          TabOrder = 6
        end
        object edtColabRFID: TEdit
          Left = 20
          Top = 197
          Width = 220
          Height = 23
          TabOrder = 7
        end
        object edtColabBarras: TEdit
          Left = 250
          Top = 197
          Width = 215
          Height = 23
          TabOrder = 8
        end
        object cmbColabHorario: TComboBox
          Left = 20
          Top = 243
          Width = 445
          Height = 23
          Style = csDropDownList
          TabOrder = 9
        end
        object chkColabAdmin: TCheckBox
          Left = 20
          Top = 275
          Width = 190
          Height = 19
          Caption = 'Administrador no Rel'#243'gio'
          TabOrder = 10
        end
        object chkColabAtivo: TCheckBox
          Left = 250
          Top = 275
          Width = 150
          Height = 19
          Caption = 'Colaborador Ativo'
          Checked = True
          State = cbChecked
          TabOrder = 11
        end
        object grpInfoSinc: TGroupBox
          Left = 20
          Top = 302
          Width = 445
          Height = 125
          Caption = ' Sincroniza'#231#227'o com o Ponto '
          TabOrder = 13
          object lblColabRelogioDestino: TLabel
            Left = 15
            Top = 20
            Width = 114
            Height = 15
            Caption = 'Enviar para o Rel'#243'gio:'
          end
          object lblColabSyncStatusLabel: TLabel
            Left = 15
            Top = 72
            Width = 35
            Height = 15
            Caption = 'Status:'
          end
          object lblColabSyncStatus: TLabel
            Left = 65
            Top = 72
            Width = 166
            Height = 15
            Caption = #9203' Pendente de Sincroniza'#231#227'o'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = 3355443
            Font.Height = -12
            Font.Name = 'Segoe UI'
            Font.Style = [fsBold]
            ParentFont = False
          end
          object lblColabUltimaSyncLabel: TLabel
            Left = 15
            Top = 95
            Width = 71
            Height = 15
            Caption = #218'ltimo Envio:'
          end
          object lblColabUltimaSync: TLabel
            Left = 95
            Top = 95
            Width = 80
            Height = 15
            Caption = 'Nunca enviado'
          end
          object cmbColabRelogioDestino: TComboBox
            Left = 15
            Top = 38
            Width = 415
            Height = 23
            Style = csDropDownList
            TabOrder = 0
          end
        end
        object pnlColabBtns: TPanel
          Left = 20
          Top = 436
          Width = 445
          Height = 88
          BevelOuter = bvNone
          Color = clWhitesmoke
          ParentBackground = False
          TabOrder = 12
          object btnSalvarColab: TButton
            Left = 0
            Top = 4
            Width = 105
            Height = 36
            Caption = 'Salvar'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -12
            Font.Name = 'Segoe UI'
            Font.Style = [fsBold]
            ParentFont = False
            TabOrder = 0
            OnClick = btnSalvarColabClick
          end
          object btnSalvarEnviarColab: TButton
            Left = 115
            Top = 4
            Width = 220
            Height = 36
            Caption = 'Salvar e Enviar ao Ponto'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -12
            Font.Name = 'Segoe UI'
            Font.Style = [fsBold]
            ParentFont = False
            TabOrder = 1
            OnClick = btnSalvarEnviarColabClick
          end
          object btnNovoColab: TButton
            Left = 345
            Top = 4
            Width = 95
            Height = 36
            Caption = 'Novo'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -12
            Font.Name = 'Segoe UI'
            Font.Style = [fsBold]
            ParentFont = False
            TabOrder = 2
            OnClick = btnNovoColabClick
          end
          object btnRemoverColabForm: TButton
            Left = 0
            Top = 46
            Width = 190
            Height = 36
            Caption = 'Remover do Rel'#243'gio'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -12
            Font.Name = 'Segoe UI'
            Font.Style = [fsBold]
            ParentFont = False
            TabOrder = 3
            OnClick = btnRemoverColabFormClick
          end
          object btnExcluirColabBanco: TButton
            Left = 200
            Top = 46
            Width = 190
            Height = 36
            Caption = 'Excluir do Banco'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -12
            Font.Name = 'Segoe UI'
            Font.Style = [fsBold]
            ParentFont = False
            TabOrder = 4
            OnClick = btnExcluirColabBancoClick
          end
        end
      end
    end
    object tabMarcacoes: TTabSheet
      Caption = '  Marca'#231#245'es de Ponto  '
      ImageIndex = 3
      object pnlMarcacoesFiltro: TPanel
        Left = 0
        Top = 0
        Width = 1092
        Height = 65
        Align = alTop
        BevelOuter = bvNone
        Color = 15724527
        ParentBackground = False
        TabOrder = 0
        object lblDtIni: TLabel
          Left = 15
          Top = 12
          Width = 61
          Height = 15
          Caption = 'Data Inicial:'
        end
        object lblDtFim: TLabel
          Left = 135
          Top = 12
          Width = 55
          Height = 15
          Caption = 'Data Final:'
        end
        object lblFiltroRelogio: TLabel
          Left = 260
          Top = 12
          Width = 43
          Height = 15
          Caption = 'Rel'#243'gio:'
        end
        object lblTotalMarcacoesGrid: TLabel
          Left = 880
          Top = 33
          Width = 114
          Height = 17
          Caption = 'Total: 0 marca'#231#245'es'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = 2761244
          Font.Height = -13
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object dtpIni: TDateTimePicker
          Left = 15
          Top = 30
          Width = 110
          Height = 23
          Date = 46288.000000000000000000
          Time = 0.500000000000000000
          TabOrder = 0
        end
        object dtpFim: TDateTimePicker
          Left = 135
          Top = 30
          Width = 110
          Height = 23
          Date = 46288.000000000000000000
          Time = 0.500000000000000000
          TabOrder = 1
        end
        object cmbFiltroRelogio: TComboBox
          Left = 260
          Top = 30
          Width = 220
          Height = 23
          Style = csDropDownList
          TabOrder = 2
        end
        object btnFiltrarMarcacoes: TButton
          Left = 495
          Top = 26
          Width = 110
          Height = 30
          Caption = 'Filtrar'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
          TabOrder = 3
          OnClick = btnFiltrarMarcacoesClick
        end
        object btnEditarMarcacao: TButton
          Left = 615
          Top = 26
          Width = 125
          Height = 30
          Caption = 'Corrigir Batida'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
          TabOrder = 4
          OnClick = btnEditarMarcacaoClick
        end
        object btnNovaMarcacao: TButton
          Left = 750
          Top = 26
          Width = 125
          Height = 30
          Caption = 'Incluir Batida'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
          TabOrder = 5
          OnClick = btnNovaMarcacaoClick
        end
        object btnExportarAFD: TButton
          Left = 885
          Top = 26
          Width = 130
          Height = 30
          Caption = 'Exportar AFD'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
          TabOrder = 6
          OnClick = btnExportarAFDClick
        end
        object btnExcluirMarcacao: TButton
          Left = 1025
          Top = 26
          Width = 125
          Height = 30
          Caption = 'Excluir Batida'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
          TabOrder = 7
          OnClick = btnExcluirMarcacaoClick
        end
      end
      object dbgMarcacoes: TDBGrid
        Left = 0
        Top = 65
        Width = 1092
        Height = 515
        Align = alClient
        Options = [dgTitles, dgIndicator, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgRowSelect, dgAlwaysShowSelection, dgConfirmDelete, dgCancelOnExit]
        ReadOnly = True
        TabOrder = 1
        TitleFont.Charset = DEFAULT_CHARSET
        TitleFont.Color = clWindowText
        TitleFont.Height = -12
        TitleFont.Name = 'Segoe UI'
        TitleFont.Style = []
        OnDrawColumnCell = dbgGridDrawColumnCell
      end
    end
    object tabConfig: TTabSheet
      Caption = '  Configura'#231#245'es  '
      ImageIndex = 4
      TabVisible = False
      object btnConfigVoltar: TButton
        Left = 450
        Top = 470
        Width = 180
        Height = 40
        Caption = 'Voltar ao Sistema'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 5
        OnClick = btnConfigVoltarClick
      end
      object grpBanco: TGroupBox
        Left = 30
        Top = 20
        Width = 600
        Height = 280
        Caption = ' Conex'#227'o com Banco de Dados Firebird '
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 0
        object lblCfgServer: TLabel
          Left = 20
          Top = 35
          Width = 46
          Height = 15
          Caption = 'Servidor:'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
        end
        object lblCfgPorta: TLabel
          Left = 390
          Top = 35
          Width = 31
          Height = 15
          Caption = 'Porta:'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
        end
        object lblCfgDatabase: TLabel
          Left = 20
          Top = 90
          Width = 130
          Height = 15
          Caption = 'Caminho da Base (.FDB):'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
        end
        object lblCfgUser: TLabel
          Left = 20
          Top = 145
          Width = 43
          Height = 15
          Caption = 'Usu'#225'rio:'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
        end
        object lblCfgPass: TLabel
          Left = 240
          Top = 145
          Width = 35
          Height = 15
          Caption = 'Senha:'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
        end
        object lblCfgVendor: TLabel
          Left = 20
          Top = 200
          Width = 146
          Height = 15
          Caption = 'Biblioteca Cliente (fbclient):'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
        end
        object edtCfgServer: TEdit
          Left = 20
          Top = 55
          Width = 350
          Height = 23
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
          TabOrder = 0
        end
        object edtCfgPorta: TEdit
          Left = 390
          Top = 55
          Width = 100
          Height = 23
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
          TabOrder = 1
        end
        object edtCfgDatabase: TEdit
          Left = 20
          Top = 110
          Width = 550
          Height = 23
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
          TabOrder = 2
        end
        object edtCfgUser: TEdit
          Left = 20
          Top = 165
          Width = 200
          Height = 23
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
          TabOrder = 3
        end
        object edtCfgPass: TEdit
          Left = 240
          Top = 165
          Width = 200
          Height = 23
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
          PasswordChar = '*'
          TabOrder = 4
        end
        object edtCfgVendor: TEdit
          Left = 20
          Top = 220
          Width = 550
          Height = 23
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
          TabOrder = 5
        end
      end
      object grpColetaAuto: TGroupBox
        Left = 30
        Top = 320
        Width = 600
        Height = 130
        Caption = ' Par'#226'metros de Coleta Autom'#225'tica '
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 1
        object lblIntervalo: TLabel
          Left = 20
          Top = 35
          Width = 184
          Height = 15
          Caption = 'Intervalo de Coleta (em segundos):'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
        end
        object edtIntervalo: TEdit
          Left = 20
          Top = 55
          Width = 120
          Height = 23
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
          TabOrder = 0
          Text = '60'
        end
        object chkAutoIniciar: TCheckBox
          Left = 20
          Top = 90
          Width = 350
          Height = 19
          Caption = 'Iniciar Coleta Autom'#225'tica ao abrir o integrador'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
          TabOrder = 1
        end
      end
      object btnSalvarConfig: TButton
        Left = 30
        Top = 470
        Width = 195
        Height = 40
        Caption = 'Salvar Configura'#231#245'es'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 2
        OnClick = btnSalvarConfigClick
      end
      object btnTestarConexaoFB: TButton
        Left = 240
        Top = 470
        Width = 195
        Height = 40
        Caption = 'Testar Conex'#227'o'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 3
        OnClick = btnTestarConexaoFBClick
      end
      object grpEmpregador: TGroupBox
        Left = 650
        Top = 20
        Width = 500
        Height = 490
        Caption = ' Dados do Empregador (Portaria 671 / 1510 MTE) '
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 4
        object lblEmpTipoDoc: TLabel
          Left = 20
          Top = 28
          Width = 109
          Height = 15
          Caption = 'Tipo de Documento:'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
        end
        object lblEmpCpfCnpj: TLabel
          Left = 165
          Top = 28
          Width = 155
          Height = 15
          Caption = 'CNPJ / CPF do Empregador *:'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
        end
        object lblEmpRazaoSocial: TLabel
          Left = 20
          Top = 80
          Width = 120
          Height = 15
          Caption = 'Raz'#227'o Social / Nome *:'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
        end
        object lblEmpCpfResp: TLabel
          Left = 20
          Top = 132
          Width = 226
          Height = 15
          Caption = 'CPF do Respons'#225'vel (Obrigat'#243'rio p/ CNPJ):'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
        end
        object lblEmpCEI: TLabel
          Left = 260
          Top = 132
          Width = 103
          Height = 15
          Caption = 'CEI / CNO / CAEPF:'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
        end
        object lblEmpEndereco: TLabel
          Left = 20
          Top = 184
          Width = 227
          Height = 15
          Caption = 'Endere'#231'o / Local da Presta'#231#227'o do Servi'#231'o *:'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
        end
        object lblEmpRelogioDestino: TLabel
          Left = 20
          Top = 236
          Width = 114
          Height = 15
          Caption = 'Enviar para o Rel'#243'gio:'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
        end
        object lblEmpInfo: TLabel
          Left = 20
          Top = 400
          Width = 460
          Height = 65
          AutoSize = False
          Caption = 
            'Aten'#231#227'o: O cadastro do empregador '#233' obrigat'#243'rio no rel'#243'gio de po' +
            'nto para liberar o cadastro de colaboradores.'#13#10'Ao alterar a empr' +
            'esa, o rel'#243'gio grava um registro fiscal (Portaria 671) e passa a' +
            ' emitir comprovantes com o novo CNPJ.'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clGrayText
          Font.Height = -11
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
          WordWrap = True
        end
        object cmbEmpTipoDoc: TComboBox
          Left = 20
          Top = 46
          Width = 130
          Height = 23
          Style = csDropDownList
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = []
          ItemIndex = 0
          ParentFont = False
          TabOrder = 0
          Text = '1 - CNPJ'
          Items.Strings = (
            '1 - CNPJ'
            '2 - CPF')
        end
        object edtEmpCpfCnpj: TEdit
          Left = 165
          Top = 46
          Width = 315
          Height = 23
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
          TabOrder = 1
        end
        object edtEmpRazaoSocial: TEdit
          Left = 20
          Top = 98
          Width = 460
          Height = 23
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
          TabOrder = 2
        end
        object edtEmpCpfResp: TEdit
          Left = 20
          Top = 150
          Width = 220
          Height = 23
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
          TabOrder = 3
        end
        object edtEmpCEI: TEdit
          Left = 260
          Top = 150
          Width = 220
          Height = 23
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
          TabOrder = 4
        end
        object edtEmpEndereco: TEdit
          Left = 20
          Top = 202
          Width = 460
          Height = 23
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
          TabOrder = 5
        end
        object cmbEmpRelogioDestino: TComboBox
          Left = 20
          Top = 254
          Width = 460
          Height = 23
          Style = csDropDownList
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
          TabOrder = 6
        end
        object btnCarregarEmpBanco: TButton
          Left = 20
          Top = 295
          Width = 220
          Height = 36
          Caption = 'Carregar do Banco'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
          TabOrder = 7
          OnClick = btnCarregarEmpBancoClick
        end
        object btnSalvarEmpBanco: TButton
          Left = 260
          Top = 295
          Width = 220
          Height = 36
          Caption = 'Salvar no Banco'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
          TabOrder = 8
          OnClick = btnSalvarEmpBancoClick
        end
        object btnEnviarEmpRelogio: TButton
          Left = 20
          Top = 345
          Width = 220
          Height = 40
          Caption = 'Enviar ao Rel'#243'gio'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
          TabOrder = 9
          OnClick = btnEnviarEmpRelogioClick
        end
        object btnLerEmpRelogio: TButton
          Left = 260
          Top = 345
          Width = 220
          Height = 40
          Caption = 'Ler do Rel'#243'gio'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
          TabOrder = 10
          OnClick = btnLerEmpRelogioClick
        end
      end
    end
    object tabHorarios: TTabSheet
      Caption = '  Hor'#225'rios & Jornadas  '
      ImageIndex = 5
      object splHorario: TSplitter
        Left = 605
        Top = 0
        Width = 5
        Height = 580
        Align = alRight
      end
      object pnlHorariosGrid: TPanel
        Left = 0
        Top = 0
        Width = 605
        Height = 580
        Align = alClient
        BevelOuter = bvNone
        TabOrder = 0
        object pnlHorariosTop: TPanel
          Left = 0
          Top = 0
          Width = 605
          Height = 45
          Align = alTop
          BevelOuter = bvNone
          Color = 16382457
          ParentBackground = False
          TabOrder = 0
          object btnNovoHorario: TButton
            Left = 12
            Top = 6
            Width = 145
            Height = 32
            Caption = 'Novo Hor'#225'rio'
            TabOrder = 0
            OnClick = btnNovoHorarioClick
          end
          object btnAtualizarHorarios: TButton
            Left = 165
            Top = 6
            Width = 110
            Height = 32
            Caption = 'Atualizar'
            TabOrder = 1
            OnClick = btnAtualizarHorariosClick
          end
        end
        object dbgHorarios: TDBGrid
          Left = 0
          Top = 45
          Width = 605
          Height = 535
          Align = alClient
          BorderStyle = bsNone
          Options = [dgTitles, dgIndicator, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgRowSelect, dgAlwaysShowSelection, dgConfirmDelete, dgCancelOnExit]
          ReadOnly = True
          TabOrder = 1
          TitleFont.Charset = DEFAULT_CHARSET
          TitleFont.Color = clWindowText
          TitleFont.Height = -12
          TitleFont.Name = 'Segoe UI'
          TitleFont.Style = []
          OnCellClick = dbgHorariosCellClick
          OnDrawColumnCell = dbgGridDrawColumnCell
        end
      end
      object pnlHorarioForm: TPanel
        Left = 610
        Top = 0
        Width = 482
        Height = 580
        Align = alRight
        BevelOuter = bvNone
        Color = clWhitesmoke
        ParentBackground = False
        TabOrder = 1
        object lblHorFormTitle: TLabel
          Left = 20
          Top = 12
          Width = 188
          Height = 17
          Caption = 'Dados da Jornada de Trabalho'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = 2761244
          Font.Height = -13
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object lblHorDescricao: TLabel
          Left = 20
          Top = 38
          Width = 119
          Height = 15
          Caption = 'Descri'#231#227'o da Jornada *'
        end
        object lblHorEntrada1: TLabel
          Left = 20
          Top = 85
          Width = 54
          Height = 15
          Caption = '1'#170' Entrada'
        end
        object lblHorSaida1: TLabel
          Left = 135
          Top = 85
          Width = 42
          Height = 15
          Caption = '1'#170' Sa'#237'da'
        end
        object lblHorEntrada2: TLabel
          Left = 250
          Top = 85
          Width = 54
          Height = 15
          Caption = '2'#170' Entrada'
        end
        object lblHorSaida2: TLabel
          Left = 365
          Top = 85
          Width = 42
          Height = 15
          Caption = '2'#170' Sa'#237'da'
        end
        object lblHorTolerancia: TLabel
          Left = 20
          Top = 135
          Width = 132
          Height = 15
          Caption = 'Toler'#226'ncia CLT (minutos)'
        end
        object lblHorCarga: TLabel
          Left = 250
          Top = 135
          Width = 176
          Height = 15
          Caption = 'Carga Di'#225'ria (minutos: 528=8h48)'
        end
        object lblHorSabEntrada1: TLabel
          Left = 20
          Top = 220
          Width = 82
          Height = 15
          Caption = 'S'#225'bado Entrada'
        end
        object lblHorSabSaida1: TLabel
          Left = 250
          Top = 220
          Width = 70
          Height = 15
          Caption = 'S'#225'bado Sa'#237'da'
        end
        object edtHorDescricao: TEdit
          Left = 20
          Top = 56
          Width = 440
          Height = 23
          TabOrder = 0
        end
        object edtHorEntrada1: TEdit
          Left = 20
          Top = 103
          Width = 95
          Height = 23
          TabOrder = 1
          Text = '08:00'
        end
        object edtHorSaida1: TEdit
          Left = 135
          Top = 103
          Width = 95
          Height = 23
          TabOrder = 2
          Text = '12:00'
        end
        object edtHorEntrada2: TEdit
          Left = 250
          Top = 103
          Width = 95
          Height = 23
          TabOrder = 3
          Text = '13:12'
        end
        object edtHorSaida2: TEdit
          Left = 365
          Top = 103
          Width = 95
          Height = 23
          TabOrder = 4
          Text = '18:00'
        end
        object edtHorTolerancia: TEdit
          Left = 20
          Top = 153
          Width = 210
          Height = 23
          TabOrder = 5
          Text = '10'
        end
        object edtHorCarga: TEdit
          Left = 250
          Top = 153
          Width = 210
          Height = 23
          TabOrder = 6
          Text = '528'
        end
        object chkHorCompensaSab: TCheckBox
          Left = 20
          Top = 190
          Width = 220
          Height = 19
          Caption = 'S'#225'bado Compensado (Folga)'
          Checked = True
          State = cbChecked
          TabOrder = 7
        end
        object chkHorTrabalhaSab: TCheckBox
          Left = 250
          Top = 190
          Width = 210
          Height = 19
          Caption = 'Trabalha aos S'#225'bados'
          TabOrder = 8
        end
        object edtHorSabEntrada1: TEdit
          Left = 20
          Top = 238
          Width = 210
          Height = 23
          TabOrder = 9
          Text = '08:00'
        end
        object edtHorSabSaida1: TEdit
          Left = 250
          Top = 238
          Width = 210
          Height = 23
          TabOrder = 10
          Text = '12:00'
        end
        object chkHorAtivo: TCheckBox
          Left = 20
          Top = 275
          Width = 150
          Height = 19
          Caption = 'Hor'#225'rio Ativo'
          Checked = True
          State = cbChecked
          TabOrder = 11
        end
        object pnlHorarioBtns: TPanel
          Left = 20
          Top = 315
          Width = 440
          Height = 85
          BevelOuter = bvNone
          Color = clWhitesmoke
          ParentBackground = False
          TabOrder = 12
          object btnSalvarHorario: TButton
            Left = 0
            Top = 4
            Width = 110
            Height = 36
            Caption = 'Salvar'
            TabOrder = 0
            OnClick = btnSalvarHorarioClick
          end
          object btnSalvarEnviarHorario: TButton
            Left = 118
            Top = 4
            Width = 205
            Height = 36
            Caption = 'Salvar e Atualizar Ponto'
            TabOrder = 1
            OnClick = btnSalvarEnviarHorarioClick
          end
          object btnNovoHorarioForm: TButton
            Left = 330
            Top = 4
            Width = 100
            Height = 36
            Caption = 'Limpar / Novo'
            TabOrder = 2
            OnClick = btnNovoHorarioClick
          end
          object btnExcluirHorario: TButton
            Left = 0
            Top = 45
            Width = 140
            Height = 36
            Caption = 'Excluir Hor'#225'rio'
            TabOrder = 3
            OnClick = btnExcluirHorarioClick
          end
        end
      end
    end
    object tabEspelho: TTabSheet
      Caption = '  Espelho de Ponto  '
      ImageIndex = 6
      object pnlEspelhoTop: TPanel
        Left = 0
        Top = 0
        Width = 1092
        Height = 65
        Align = alTop
        BevelOuter = bvNone
        Color = 16382457
        ParentBackground = False
        TabOrder = 0
        object lblEspelhoColab: TLabel
          Left = 15
          Top = 8
          Width = 69
          Height = 15
          Caption = 'Colaborador:'
        end
        object lblEspelhoPeriodo: TLabel
          Left = 265
          Top = 8
          Width = 44
          Height = 15
          Caption = 'Per'#237'odo:'
        end
        object lblEspelhoAte: TLabel
          Left = 377
          Top = 30
          Width = 16
          Height = 15
          Caption = 'at'#233
        end
        object cmbEspelhoColab: TComboBox
          Left = 15
          Top = 26
          Width = 240
          Height = 23
          Style = csDropDownList
          TabOrder = 0
        end
        object dtpEspelhoIni: TDateTimePicker
          Left = 265
          Top = 26
          Width = 105
          Height = 23
          Date = 46289.000000000000000000
          Time = 46289.000000000000000000
          TabOrder = 1
        end
        object dtpEspelhoFim: TDateTimePicker
          Left = 400
          Top = 26
          Width = 105
          Height = 23
          Date = 46289.000000000000000000
          Time = 0.999988425923220300
          TabOrder = 2
        end
        object btnCalcularEspelho: TButton
          Left = 518
          Top = 18
          Width = 145
          Height = 36
          Caption = 'Apurar Ponto'
          TabOrder = 3
          OnClick = btnCalcularEspelhoClick
        end
        object btnLancarJustificativa: TButton
          Left = 672
          Top = 18
          Width = 180
          Height = 36
          Caption = 'Lan'#231'ar Ocorr'#234'ncia'
          TabOrder = 4
          OnClick = btnLancarJustificativaClick
        end
        object btnExportarEspelhoHTML: TButton
          Left = 860
          Top = 18
          Width = 205
          Height = 36
          Caption = 'Visualizar / Imprimir'
          TabOrder = 5
          OnClick = btnExportarEspelhoHTMLClick
        end
        object btnCorrigirBatidaEspelho: TButton
          Left = 1075
          Top = 18
          Width = 190
          Height = 36
          Caption = 'Corrigir / Incluir Batida'
          TabOrder = 6
          OnClick = btnCorrigirBatidaEspelhoClick
        end
      end
      object grdEspelho: TStringGrid
        Left = 0
        Top = 65
        Width = 1092
        Height = 445
        Align = alClient
        BorderStyle = bsNone
        ColCount = 13
        FixedCols = 0
        RowCount = 2
        Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goRowSelect]
        TabOrder = 1
        OnDrawCell = grdEspelhoDrawCell
      end
      object pnlEspelhoResumo: TPanel
        Left = 0
        Top = 510
        Width = 1092
        Height = 70
        Align = alBottom
        BevelOuter = bvNone
        Color = clWhite
        ParentBackground = False
        TabOrder = 2
        object pnlCardEsp1: TPanel
          Left = 15
          Top = 10
          Width = 190
          Height = 50
          BevelOuter = bvNone
          Color = 16382457
          ParentBackground = False
          TabOrder = 0
          object lblCardEsp1Title: TLabel
            Left = 10
            Top = 6
            Width = 67
            Height = 13
            Caption = 'Previsto Total'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = 7829367
            Font.Height = -11
            Font.Name = 'Segoe UI'
            Font.Style = []
            ParentFont = False
          end
          object lblCardEsp1Val: TLabel
            Left = 10
            Top = 22
            Width = 40
            Height = 21
            Caption = '00:00'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = 2761244
            Font.Height = -16
            Font.Name = 'Segoe UI'
            Font.Style = [fsBold]
            ParentFont = False
          end
        end
        object pnlCardEsp2: TPanel
          Left = 215
          Top = 10
          Width = 190
          Height = 50
          BevelOuter = bvNone
          Color = 16382457
          ParentBackground = False
          TabOrder = 1
          object lblCardEsp2Title: TLabel
            Left = 10
            Top = 6
            Width = 77
            Height = 13
            Caption = 'Realizado Total'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = 7829367
            Font.Height = -11
            Font.Name = 'Segoe UI'
            Font.Style = []
            ParentFont = False
          end
          object lblCardEsp2Val: TLabel
            Left = 10
            Top = 22
            Width = 40
            Height = 21
            Caption = '00:00'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = 2761244
            Font.Height = -16
            Font.Name = 'Segoe UI'
            Font.Style = [fsBold]
            ParentFont = False
          end
        end
        object pnlCardEsp3: TPanel
          Left = 415
          Top = 10
          Width = 190
          Height = 50
          BevelOuter = bvNone
          Color = 15335147
          ParentBackground = False
          TabOrder = 2
          object lblCardEsp3Title: TLabel
            Left = 10
            Top = 6
            Width = 63
            Height = 13
            Caption = 'Horas Extras'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = 3051058
            Font.Height = -11
            Font.Name = 'Segoe UI'
            Font.Style = []
            ParentFont = False
          end
          object lblCardEsp3Val: TLabel
            Left = 10
            Top = 22
            Width = 51
            Height = 21
            Caption = '+00:00'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = 3051058
            Font.Height = -16
            Font.Name = 'Segoe UI'
            Font.Style = [fsBold]
            ParentFont = False
          end
        end
        object pnlCardEsp4: TPanel
          Left = 615
          Top = 10
          Width = 190
          Height = 50
          BevelOuter = bvNone
          Color = 15724542
          ParentBackground = False
          TabOrder = 3
          object lblCardEsp4Title: TLabel
            Left = 10
            Top = 6
            Width = 73
            Height = 13
            Caption = 'Faltas / Atraso'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = 3158213
            Font.Height = -11
            Font.Name = 'Segoe UI'
            Font.Style = []
            ParentFont = False
          end
          object lblCardEsp4Val: TLabel
            Left = 10
            Top = 22
            Width = 46
            Height = 21
            Caption = '-00:00'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = 3158213
            Font.Height = -16
            Font.Name = 'Segoe UI'
            Font.Style = [fsBold]
            ParentFont = False
          end
        end
        object pnlCardEsp5: TPanel
          Left = 815
          Top = 10
          Width = 250
          Height = 50
          BevelOuter = bvNone
          Color = 16382457
          ParentBackground = False
          TabOrder = 4
          object lblCardEsp5Title: TLabel
            Left = 10
            Top = 6
            Width = 89
            Height = 13
            Caption = 'Saldo do Per'#237'odo'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = 7829367
            Font.Height = -11
            Font.Name = 'Segoe UI'
            Font.Style = []
            ParentFont = False
          end
          object lblCardEsp5Val: TLabel
            Left = 10
            Top = 22
            Width = 51
            Height = 21
            Caption = '+00:00'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = 2761244
            Font.Height = -16
            Font.Name = 'Segoe UI'
            Font.Style = [fsBold]
            ParentFont = False
          end
        end
      end
    end
  end
  object stbMain: TStatusBar
    Left = 0
    Top = 695
    Width = 1100
    Height = 25
    Panels = <
      item
        Text = 'Banco Firebird: Conectando...'
        Width = 350
      end
      item
        Text = 'Coleta Autom'#225'tica: Desativada'
        Width = 250
      end
      item
        Text = 'Status: Pronto'
        Width = 300
      end
      item
        Alignment = taRightJustify
        Text = 'Delphi 12 Athens'
        Width = 50
      end>
  end
  object tmrAutoColeta: TTimer
    Enabled = False
    Interval = 60000
    OnTimer = tmrAutoColetaTimer
    Left = 320
    Top = 16
  end
  object dlgSave: TSaveDialog
    DefaultExt = 'txt'
    Filter = 'Arquivo Texto (*.txt)|*.txt|Todos os Arquivos (*.*)|*.*'
    Left = 416
    Top = 16
  end
end
