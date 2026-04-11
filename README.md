# Arco - Duelo de Arqueiros (Godot 4)

Projeto Godot 2D simples e expansível: dois arqueiros nas laterais atiram flechas um no outro.

## Como executar

1. Instale o **Godot 4 (última versão estável)**.
2. Abra o Godot e clique em **Import**.
3. Selecione a pasta deste repositório (onde está o arquivo `project.godot`).
4. Abra o projeto e aperte **F5** (Run).

## Controles

- **Player 1 (esquerda)**:
  - Mover: **A / D**
  - Atirar: **F**
- **Player 2 (direita)**:
  - Mover: **Setas Esquerda / Direita**
  - Atirar: **L**

## Estrutura

Organização alinhada ao guia Godot em `docs/project_organization.rst` (`snake_case`, recursos junto às cenas em `projectiles/`).

- `project.godot`: configurações do projeto + Input Map
- `docs/.gdignore`: a pasta `docs/` não é importada pelo editor
- `core/run_config.gd`: autoload (modo de jogo, personagens)
- `ui/menu.tscn` + `ui/menu.gd`: menu principal
- `levels/duel/main.tscn` + `levels/duel/game.gd`: cena de duelo e coordenação (spawn, regras)
- `levels/duel/pause_menu_controller.gd`: pausa durante o duelo
- `characters/`: scripts base e variantes de jogador (`player.gd`, etc.)
- `projectiles/<nome>/`: cada projétil com `.tscn` e `.gd` na mesma pasta (ex.: `projectiles/arrow/`)

## Observações

- A flecha é um `Area2D` com gravidade manual (movimento de projétil).
- Colisão: jogadores estão na **layer 1** e flechas na **layer 2** (máscara da flecha inclui a layer 1).
