# Atualização consultada na Play Store

Pedido aprovado em 04/11/2026: manter a notinha de caderno e consultar a
disponibilidade pela Play para a conta instalada, sem publicação manual de JSON.

Etapas: plugin Android v2 isolado com Play App Update 2.1.0; consulta com prazo;
Hub abre a notinha só quando a loja confirma código maior; JSON fornece apenas
textos da mesma versão. Falha de textos usa mensagem genérica. Botão abre a loja.
Sem iniciar instalação ou obrigar atualização. Falha da consulta não abre aviso.

Validar: compilar AAR, testes do Hub com respostas simuladas, exportar release e
conferir plugin/dependência no AAB. Disponibilidade real exige instalação pela
Play e uma versão superior liberada à mesma conta; PC não comprova essa etapa.

Fontes oficiais:
- https://developer.android.com/guide/playcore/in-app-updates/kotlin-java
- https://docs.godotengine.org/en/stable/tutorials/platform/android/android_plugin.html

## Implementado e validado — 04/11/2026
- Plugin v2 `SketchBladePlayUpdate`: somente consulta `getAppUpdateInfo`,
  comunica disponibilidade e código. Não requer credenciais ou API paga.
- `AtualizacaoLoja.gd` espera até 8 s. Plugin ausente, erro, versão igual ou
  timeout não abrem aviso. `Hub` pede textos por até 3 s após confirmar a Play.
- JSON antigo, inválido ou indisponível não bloqueia o aviso: mensagem genérica
  na mesma folha. Notas e nome da versão só entram se o código coincidir com a
  versão oferecida à conta. Isso também evita textos de um rollout mais novo.
- Botão ATUALIZAR continua abrindo a Play Store; Agora não vale até reiniciar.
- Trava de duplicação fica antes da espera da recompensa diária.
- 16 verificações de lógica passaram (`tools/teste_atualizacao_play.gd`; alias
  `tools/teste_aviso_atualizacao.gd`). Save restaurado com hash idêntico. O teste
  headless informa recursos residuais ao encerrar, sem falhas nas verificações.
- AAR compilado com AGP 8.6.1 / Java 21 / compileSdk 36 / minSdk 24.
  Java 25 padrão não funciona com este Gradle. AndroidX precisa estar habilitado.
- Recompilar AAR após alterar Java: definir JAVA_HOME para o JBR 21 instalado,
  configurar `tools/play_update_android/local.properties` com sdk.dir e executar
  `android/build/gradlew.bat -p tools/play_update_android installPlugin`.
  O wrapper e o AAR do Godot vêm da instalação do template Android do projeto.
  Saída versionada: `addons/play_update/bin/play-update.aar` (plugin de export
  acrescenta a dependência Maven do Google). Nenhuma modificação manual no
  template ignorado em android/ é necessária.
- Serena estava disponível, mas o servidor GDScript não conectou na porta 6008;
  investigação e testes continuaram pelas ferramentas locais.

## Teste no celular ainda necessário
Instalar esta integração pela Play (1.8.3/18), depois disponibilizar uma versão
superior à mesma conta. Abrir o jogo antigo: a notinha deve surgir mesmo que o
JSON não tenha sido atualizado. Quem já está na versão mais nova não deve vê-la.
Instalação lateral/PC não comprova disponibilidade real do Google Play.
Versões anteriores à 1.8.3 ainda dependem do JSON antigo para detectar atualização.
