object dmDados: TdmDados
  OldCreateOrder = False
  OnCreate = DataModuleCreate
  OnDestroy = DataModuleDestroy
  Height = 280
  Width = 380
  object FDConnection: TFDConnection
    Params.Strings = (
      'DriverID=FB'
      'User_Name=SYSDBA'
      'Password=masterkey'
      'Port=3060'
      'CharacterSet=WIN1252')
    LoginPrompt = False
    Left = 56
    Top = 40
  end
  object FDPhysFBDriverLink: TFDPhysFBDriverLink
    Left = 168
    Top = 40
  end
  object FDGUIxWaitCursor: TFDGUIxWaitCursor
    Provider = 'Forms'
    Left = 280
    Top = 40
  end
end
