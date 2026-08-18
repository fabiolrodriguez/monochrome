# Project Monochrome

Action roguelite 2D em Godot 4.7, construído incrementalmente a partir do GDD do projeto.

## Estado atual

Fundação do **Milestone 1 — movimento + tiro**:

- viewport lógico 320×180, escala inteira e filtering nearest;
- movimento em 8 direções com teclado ou analógico esquerdo;
- mira independente com mouse ou analógico direito;
- tiro contínuo com botão esquerdo ou RT;
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
  presentation/  desenho, efeitos e UI
assets/          arte, áudio e fontes substituíveis
tests/           testes automatizados quando o primeiro domínio testável surgir
```

Não há autoloads no primeiro milestone: estado global ainda não é necessário. Managers serão introduzidos somente quando existir uma responsabilidade real e um ciclo de vida claro.

## Convenções

- GDScript com tipagem estática e `class_name` apenas para tipos reutilizados.
- Cenas compõem comportamentos pequenos; dados de conteúdo serão `Resource`.
- Textos visíveis serão localizados antes da primeira UI de produção.
- Gameplay nunca deve depender do tamanho ou formato de um sprite placeholder.
- Novos inputs devem ser adicionados ao Input Map, nunca consultados por tecla diretamente.

## Próximo milestone

Milestone 2: componente de vida/dano, três arquétipos de inimigo, projéteis inimigos e uma primeira base de pooling medida com o profiler.

