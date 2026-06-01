# Arco - Duelo de Arqueiros (Godot 4)

Projeto Godot 2D simples e expansível: dois arqueiros nas laterais atiram flechas um no outro.

## Como executar

1. Instale o **Godot 4 (última versão estável)**.
2. Abra o Godot e clique em **Import**.
3. Selecione a pasta deste repositório (onde está o arquivo `project.godot`).
4. Abra o projeto e aperte **F5** (Run).

## Controles (padrão teclado e mouse)

- **Jogador 1 (esquerda)**:
  - Mover: **A** / **D**
  - Atirar: **botão esquerdo do mouse** (no duelo; nos menus o jogo remove esse mapeamento para você poder clicar nos botões)
  - Outras ações (granada, especial, escudo, dash etc.): ver `levels/duel/game.gd` (`_ensure_input_map`) e o HUD
- **Jogador 2 (direita)**:
  - Por padrão no **Vs**: **controle** (segundo jogador no mesmo teclado com layout antigo de setas não existe mais).
  - Se escolher **teclado e mouse** no menu do Vs, usa o **mesmo** layout WASD + mouse que o jogador 1 — **só um** dos dois pode estar em teclado+mouse; o outro passa automaticamente para controle.

No **Vs** ou no **Treino**, dá para escolher **teclado e mouse** ou **controle** por jogador (e o índice do controle, se tiver mais de um ligado). Nos menus, use a **cruz direcional** ou o **analógico esquerdo**, **A** (ou Enter) para confirmar e **B** para voltar.

## Estrutura

Organização alinhada ao guia Godot em `docs/project_organization.rst` (`snake_case`, recursos junto às cenas em `projectiles/`).

Documentação de onboarding / handoff completo: **`docs/handoff_projeto.txt`**

Sistema de câmera: **`docs/sistema_camera.md`** · v1 Feixe: **`docs/camera_implementacao_v1.txt`** · v2 (KO, intro Vs, ULT, FX): **`docs/camera_implementacao_v2.txt`**

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
