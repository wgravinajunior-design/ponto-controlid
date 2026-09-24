---
description: Regra e workflow obrigatório para encoding (UTF-8 com BOM e DCC_CodePage=65001) em projetos Delphi
globs: ["**/*.pas", "**/*.dpr", "**/*.dproj", "**/*.dfm"]
---

# Regra Obrigatória de Codificação e Acentuação para Projetos Delphi

Para evitar problemas de caracteres corrompidos ("mojibake", ex: "ConexÃ£o" em vez de "Conexão", "RelÃ³gio" em vez de "Relógio", "MarcaÃ§Ã£o" em vez de "Marcação"), todos os projetos e arquivos Delphi DEVEM seguir rigorosamente o seguinte workflow:

## 1. Configuração do `.dproj`
Todo arquivo `.dproj` DEVE conter obrigatoriamente a tag `<DCC_CodePage>65001</DCC_CodePage>` na seção base:
```xml
<PropertyGroup Condition="'$(Base)'!=''">
    ...
    <DCC_CodePage>65001</DCC_CodePage>
    ...
</PropertyGroup>
```
Isso garante que o compilador (`dcc32` e `dcc64`) receba o argumento `--codepage:65001` tanto via MSBuild quanto via linha de comando ou IDE.

## 2. Gravação de Arquivos Fonte (`.pas` e `.dpr`)
- Todo arquivo `.pas` e `.dpr` criado ou editado DEVE ser gravado em **UTF-8 com BOM (Byte Order Mark `EF BB BF`)**.
- Sem o BOM, compiladores Delphi em Windows com codepage 1252 podem interpretar incorretamente os bytes multi-byte UTF-8 como caracteres ANSI individuais.

## 3. Arquivos de Formulário (`.dfm`)
- Textos com acentuação direta em propriedades DFM de componentes visuais devem preferencialmente usar a notação de caracteres do Delphi (ex: `'Rel'#243'gio'`, `'Marca'#231#245'es'`, `'Conex'#227'o'`) para compatibilidade com o leitor de formulários da VCL.
- Mensagens de log, diálogos e textos dinâmicos no código Pascal `.pas` utilizam acentuação padrão em UTF-8 com a CodePage 65001 ativa.

## 4. Script de Workflow Automático
Em qualquer projeto Delphi, utilizar o script `build.ps1` que valida o BOM dos fontes, valida o `DCC_CodePage` e executa o build limpo.
