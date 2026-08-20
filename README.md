# Project Monochrome

Action roguelite 2D em Godot 4.7, construído incrementalmente a partir do GDD do projeto.

## Estado atual

Expansão da vertical slice após os milestones principais:

- viewport lógico 320×180, escala inteira e filtering nearest;
- movimento em 8 direções com teclado ou analógico esquerdo;
- mira independente com mouse ou analógico direito;
- tiro contínuo com botão esquerdo ou RT;
- componente reutilizável de vida e dano;
- arquétipos Chaser, Shooter e Tank;
- configuração dos arquétipos por `EnemyData`, sem números de balanceamento presos ao script;
- projéteis inimigos e dano de contato;
- tileset 16×16 reaproveitável, pintado proceduralmente sem imagem de cenário estática;
- diretor de ameaça com orçamento crescente e limite de inimigos ativos;
- drops de XP com atração por proximidade;
- curva de experiência, múltiplos level ups e HUD de progresso;
- escolha pausada de um entre três upgrades com mouse, teclado ou gamepad;
- pool ponderado e níveis máximos orientados por `UpgradeData`;
- cinco upgrades funcionais: dano, cadência, movimento, vida e velocidade de projétil;
- encerramento da run ao zerar a vida, com reinício explícito;
- textos do novo fluxo em português brasileiro e inglês;
- `LevelData` para duração, pool de inimigos, progressão e conteúdo futuro;
- Void Garden com duração de seis minutos e três segmentos de pressão;
- cronômetro regressivo e conclusão da fase;
- reserva de orçamento do diretor, garantindo variedade de Chasers, Shooters e Tanks;
- objetivo de sobrevivência instanciado por cena e configurado por `ObjectiveData`;
- progresso do objetivo no HUD e conclusão desacoplada do `LevelController`;
- valores de combate da run explicitamente reiniciados ao instanciar player, arma e upgrades;
- menu de pausa com ESC/Start, continuar e reiniciar, sem conflito com outros modais;
- atlas florestal 16×16 reutilizável, com colisão e composição procedural de clareiras e pequenas salas;
- pinheiros 16×16 reutilizáveis e espaçados, com colisão independente;
- mapa em TAB/Select com setores revelados conforme a exploração;
- Void Garden delimitada por tiles florestais, com câmera e spawns restritos à área jogável;
- The Watcher configurado por `BossData`, com barra de vida e três fases de padrões;
- transição do objetivo de sobrevivência para o confronto final;
- autofire alternável pelo botão direito do mouse ou Y do controle;
- menu inicial com total permanente de moedas;
- XP garantido por inimigo e moedas como drop raro independente;
- moedas coletadas e recompensa do boss salvas automaticamente;
- save JSON versionado para moeda, fases desbloqueadas e concluídas;
- retorno ao menu principal pelo pause e encerramento de run;
- árvore permanente espacial com quinze nós conectados, custos e pré-requisitos;
- nós compactos por ícone, painel de inspeção por hover/foco e zoom de 65% a 150%;
- bônus permanentes aplicados a cada nova run e persistidos no save v2;
- nó de sistema que desbloqueia um reroll funcional por run;
- nós permanentes de unlock para Perfuração, Tiro múltiplo e Ricochete;
- upgrades bloqueados ficam fora do pool até a compra do respectivo nó;
- Multishot com dispersão simétrica, Piercing com hits adicionais e Ricochet buscando o próximo alvo;
- pool pré-aquecido e limitado para projéteis do jogador, preparado para maior densidade de tiros;
- áudio ambiente distinto no menu e em Void Garden;
- feedback sonoro para UI, disparo, impacto, coleta, dash, mortes e boss;
- ícones monocromáticos 16×16 incorporados aos cards de upgrade;
- dash com cooldown e invulnerabilidade curta;
- três upgrades defensivos funcionais: Armadura, Regeneração e Barreira;
- Elite Hunter periódico, com silhueta dourada, vida elevada e recompensa garantida;
- flash de impacto em inimigos e player;
- intensidade de flashes configurável entre desligada, reduzida e completa;
- tremor de tela opcional para dano recebido, explosões e transições de bosses;
- variações 16×16 de alvenaria aplicadas proceduralmente sobre paredes existentes;
- cards de level up com fundo preto sólido e foco dourado;
- recompensa do Watcher com XP, moedas, cura e resumo no painel de conclusão;
- seleção de fases no menu, exibindo rotas bloqueadas e desbloqueadas pelo progresso;
- drop raro de cura nos inimigos, com chance e valor maiores para elites;
- atlas Dungeon 16×16 aplicado a player, inimigos, elite, pickups, chão, vegetação, paredes e ruínas;
- arte procedural preservada somente para sinais de gameplay, como projéteis, mira, barreira e boss;
- colisão e arte placeholder desacopladas;
- layers de física nomeadas para os sistemas futuros.

Abra `project.godot` no Godot 4.7 e execute a cena principal com F6/F5.

## Organização

```text
src/
  app/           composição e ciclo de vida da aplicação
  core/          tipos e utilidades sem dependência de domínio (quando necessários)
  data/          Resources customizados e conteúdo orientado por dados
  gameplay/      player, armas, projéteis, inimigos e componentes
  levels/        cenas e lógica específica de fases
  presentation/  tilemaps, desenho, efeitos e UI
assets/          arte, áudio e fontes substituíveis
tests/           testes automatizados quando o primeiro domínio testável surgir
```

Não há autoloads no primeiro milestone: estado global ainda não é necessário. Managers serão introduzidos somente quando existir uma responsabilidade real e um ciclo de vida claro.

## Convenções

- GDScript com tipagem estática e `class_name` apenas para tipos reutilizados.
- Cenas compõem comportamentos pequenos; dados de conteúdo serão `Resource`.
- Textos visíveis serão localizados antes da primeira UI de produção.
- Toda nova interface deve incluir as chaves em inglês, português brasileiro e espanhol no mesmo milestone.
- Preferências de volume, tela cheia e idioma vivem em `user://settings.cfg`, separadas do progresso da campanha.
- Gameplay nunca deve depender do tamanho ou formato de um sprite placeholder.
- Novos inputs devem ser adicionados ao Input Map, nunca consultados por tecla diretamente.

## Próximo milestone

Próximo: raridade de upgrades e golpes críticos, ampliando a expressão das builds sem aumentar a complexidade inicial.

## Build de playtest no Windows

O preset `Windows Playtest` exporta para `build/windows/ProjectMonochrome.exe` com o PCK embutido. É necessário instalar os templates de exportação correspondentes à versão do Godot antes de gerar a build.

Os arquivos locais ficam em `%APPDATA%\Godot\app_userdata\Project Monochrome\`:

- `savegame.json`: progressão permanente;
- `settings.cfg`: volume, fullscreen e idioma;
- `run_history.jsonl`: uma linha JSON por run, útil para balanceamento.

No menu de opções da build de playtest é possível liberar todas as fases ou zerar somente a progressão. O reset exige confirmação e não apaga configurações nem o histórico das runs.

## Créditos de assets

- Efeitos e ambientes: PixelLoops Audio — Free Starter Sound Effects Pack. Licença incluída em `assets/licenses/pixelloops_audio_license.txt`.
- Ícones monocromáticos 16×16: pacote fornecido localmente para o projeto.
- Dungeon 16x16 1Bit Black and White Tileset © 2025 Stealthness Games, CC BY-NC-SA 4.0. Licença em `assets/licenses/dungeon_16x16_bw_license.txt`. Uso atual restrito ao protótipo não comercial.
- Monochrome Caves: folha modular 16×16 fornecida localmente. O download não incluía autoria/licença; origem e restrição provisória a protótipo documentadas em `assets/licenses/monochrome_caves_source.txt`. O mapa-exemplo estático não foi incorporado.
- Kenney 1-Bit Platformer Pack 1.1, CC0. O atlas transparente é usado apenas para props compatíveis com visão top-down; licença incluída em `assets/licenses/kenney_1bit_platformer_license.txt`.
- 1bitDungeon: tiles top-down e ícones de moeda/poção. Permitido em projetos comerciais e não comerciais, com edição e crédito opcional; redistribuição dos assets é proibida. Termos e cuidado para repositório público documentados em `assets/licenses/one_bit_dungeon_source.txt`.
