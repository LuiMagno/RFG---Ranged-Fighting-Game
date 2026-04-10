# RFG — Ranged Fighting Game

**RFG** (*Ranged Fighting Game*) é um jogo de combate **2D em visão lateral**, feito em **Godot 4**, onde dois jogadores se enfrentam **à distância** em uma arena. Cada um escolhe uma classe com armas e habilidades próprias: projéteis, especiais, escudo, dash e mecânicas exclusivas (por exemplo flecha fragmentada do arqueiro, granadas e magias do mago).

No editor, o projeto ainda aparece como *Arco - Duelo de Arqueiros* — nome herdado do protótipo inicial focado só em flechas — mas o escopo atual é esse **duelo ranged** com **três classes** e vários tipos de projéteis.

## Modos

- **VS**: dois humanos no mesmo teclado (P1 à esquerda, P2 à direita).
- **Treino**: você contra um alvo configurável (opção de o dummy atirar ou não).

A seleção de classe (Pistoleiro, Arqueiro, Mago) é feita no **menu principal** antes de iniciar a partida.

## Como executar

1. Instale o **Godot 4** (versão compatível com o projeto, ex.: **4.6** conforme `project.godot`).
2. Abra o Godot → **Import** → escolha a pasta onde está o arquivo `project.godot`.
3. Abra o projeto e pressione **F5** (Run).

## Controles (resumo)

| Ação | Jogador 1 (esquerda) | Jogador 2 (direita) |
|------|----------------------|----------------------|
| Mover | **A** / **D** | **←** / **→** |
| Pular | **Espaço** | **↑** |
| Pairar (eixo vertical) | **W** / **S** | **I** / **K** |
| Atirar (básico) | **Botão esquerdo do rato** | **L** |
| Especial | **G** (segurar/soltar conforme a classe) | **O** |
| Granada / estaca (classe) | **F** | **J** |
| Levitação (mago) | **C** | **Y** |
| Escudo | **Q** | **/** (barra) |
| Dash | **Shift** (esquerdo) | **Shift** (direito) |
| Pausa | **Enter** | **Enter** |

*Teclas extras podem ser conferidas em `Game.gd` (`_ensure_input_map`).*

## Estrutura do repositório

- `project.godot` — nome do app, cena inicial (`Menu.tscn`), autoload `RunConfig`.
- `scenes/` — cenas da UI, arena (`Main.tscn`), projéteis e efeitos.
- `scripts/` — lógica do menu, jogo (`Game.gd`), classes de jogador (`PistoleiroPlayer`, `ArqueiroPlayer`, `MagoPlayer`), projéteis e configuração de partida (`RunConfig.gd`).

## Stack

- **Motor:** Godot 4  
- **Linguagem:** GDScript  
- **Gênero:** arena 2D, combate à distância, multijogador local

---

Descrição curta para o GitHub (*About*): *Jogo de luta 2D em Godot 4: duelo à distância com pistoleiro, arqueiro e mago; VS local e modo treino.*
