# Regras do projeto

## Build obrigatório a cada alteração
Toda vez que o código for alterado (Delphi ou Flutter), some 1 ao número de build **antes de compilar**,
para o usuário saber qual versão está rodando (aparece no cabeçalho do app):

```powershell
.\bump_build.ps1 -App Delphi    # alterou o Delphi
.\bump_build.ps1 -App Flutter   # alterou o Flutter
.\bump_build.ps1                # alterou os dois
```

Depois de compilar, informe ao usuário o número da build nova.
Não use `build.ps1` só para isso: ele faz Rebuild completo e pode publicar release.
