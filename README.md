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

- `project.godot`: configurações do projeto + Input Map
- `scenes/Main.tscn`: cena principal (spawna jogadores e flechas)
- `scenes/Arrow.tscn`: cena da flecha
- `scripts/Game.gd`: coordena o jogo (spawn de flechas, regras futuras)
- `scripts/Player.gd`: movimento, tiro (via sinal), HP
- `scripts/Arrow.gd`: movimento balístico, colisão e cleanup

## Observações

- A flecha é um `Area2D` com gravidade manual (movimento de projétil).
- Colisão: jogadores estão na **layer 1** e flechas na **layer 2** (máscara da flecha inclui a layer 1).
