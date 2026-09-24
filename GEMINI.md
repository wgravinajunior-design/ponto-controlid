# Diretrizes e Workflow de Desenvolvimento do Projeto

## Codificação de Caracteres e Acentuação (Delphi)

1. **UTF-8 com BOM Obrigatório**:
   - Todo arquivo `.pas` e `.dpr` DEVE ser salvo em UTF-8 com BOM (`EF BB BF`).
   - Todo arquivo `.dproj` DEVE possuir a propriedade `<DCC_CodePage>65001</DCC_CodePage>`.
2. **Propriedades em `.dfm`**:
   - Textos de labels e botões em `.dfm` devem usar escape nativo de caracteres (`'Rel'#243'gio'`, `'Marca'#231#245'es'`, `'Conex'#227'o'`).
3. **Workflow de Compilação**:
   - Sempre executar `.\build.ps1` para validar codificação e compilar.
