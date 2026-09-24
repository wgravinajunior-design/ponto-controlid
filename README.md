# Integrador Ponto Control iD

Sistema completo de integração e gerenciamento de ponto eletrônico para Relógios de Ponto da linha **Control iD** (iDPax, iDClass, iDAccess).

## 🚀 Funcionalidades

- **Gerenciamento de Relógios de Ponto**: Conexão via API HTTP/HTTPS, sincronização de data/hora, teste de conectividade e monitoramento de status em tempo real.
- **Coleta de Marcações**: Coleta automática e manual de marcações AFD (Arquivo Fonte de Dados) conforme as Portarias 1510/2009 e 671/2021.
- **Espelho de Ponto Eletrônico**:
  - Apuração de jornadas de trabalho (44h semanais, sábados compensados/trabalhados, folgas).
  - Cálculo automático de horas normais, extras, atrasos, faltas e adicional noturno.
  - Justificativas e abonos legais (atestados médicos, declarações, dispensas).
  - Ajuste e correção manual de batidas diretamente no sistema com registro de auditoria.
  - Exportação e impressão de Espelho de Ponto em formato HTML/PDF.
- **Sincronização de Colaboradores**: Envio e atualização de colaboradores, matrículas, PIS, CPF e senhas para os equipamentos Control iD.
- **Auto-Migração de Banco de Dados**: Verificação e criação automática de tabelas, campos, índices e generators no Firebird a cada inicialização.
- **Auto-Update Integrado**: Verificação em segundo plano de novas versões no GitHub Releases, notificação na interface e download assistido com reinicialização automática.

## 🛠️ Tecnologias

- **Linguagem**: Delphi 12 (Athens)
- **Banco de Dados**: Firebird 2.5 / 3.0 / 4.0 / 5.0 (FireDAC)
- **Componentes Visuais**: VCL nativo com botões estilizados em Skia (SVG, gradientes modernos e bordas arredondadas)
- **Integração**: GitHub Releases API via `System.Net.HttpClient`

## 📦 Compilação e Deploy

O projeto conta com o script automatizado `build.ps1` que garante:
1. Normalização de todos os arquivos `.pas` e `.dpr` em UTF-8 com BOM.
2. Validação da diretiva `<DCC_CodePage>65001</DCC_CodePage>`.
3. Compilação Release via MSBuild.
4. Geração automática de tag e release no GitHub via parâmetro `-ReleaseVersion`.

```powershell
# Compilar projeto
.\build.ps1

# Compilar e publicar nova Release no GitHub
.\build.ps1 -ReleaseVersion "v1.0.0"
```
