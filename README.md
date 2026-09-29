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
1. Incremento automático do número de build (`version.json`) e geração de `uBuildInfo.pas` e do VerInfo do executável (`X.Y.Z.Build`).
2. Normalização de todos os arquivos `.pas` e `.dpr` em UTF-8 com BOM.
3. Validação da diretiva `<DCC_CodePage>65001</DCC_CodePage>`.
4. Compilação Release via MSBuild.
5. Commit, push e publicação da release no GitHub via parâmetro `-ReleaseVersion` (tag `vX.Y.Z`, título `vX.Y.Z (Build N)`).

```powershell
# Compilar projeto (incrementa o build)
.\build.ps1

# Compilar e publicar nova Release no GitHub
.\build.ps1 -ReleaseVersion 1.0.2 -ReleaseNotes "Descrição das novidades"
```

## 🔄 Atualização Automática

- A versão e o build aparecem no cabeçalho, no rodapé e na tela de atualização (ex.: `v1.0.1 • Build 3`).
- O sistema consulta a última release do GitHub ao abrir e a cada `IntervaloVerificacaoMin` minutos (padrão 60).
- Há atualização quando a versão da release é maior, ou a mesma versão com build maior.
- Com `AutoAtualizar=S` (padrão, configurável em Configurações), a tela de atualização abre sozinha com contagem regressiva de 15s; o usuário pode adiar.
- O executável baixado é validado (tamanho e assinatura `MZ`); o anterior fica salvo como `PontoControlID_old.exe`.

```ini
[ATUALIZACAO]
AutoAtualizar=S
IntervaloVerificacaoMin=60
```
