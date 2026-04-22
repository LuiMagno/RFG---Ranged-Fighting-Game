# Sistemas centrais: arena, movimento e física “por baixo dos panos”

Este texto descreve o **design técnico comum** do duelo 2D: dimensões, colisões, movimento, dash, pulo, limites da arena e fluxo de simulação. Os valores citados vêm de `project.godot`, `levels/duel/main.tscn` e `characters/player.gd` (salvo nota em contrário). Personagens específicos sobrescrevem sobretudo `_get_dash_stats()` e combate; ver [personagens/](personagens/) e [comparativo_personagens_vs_esqueleto.md](comparativo_personagens_vs_esqueleto.md).

---

## 1. Vista e arena

| Conceito | Valor | Onde |
|----------|--------|------|
| Resolução lógica (viewport) | **1920 × 864** px | `[display]` em `project.godot` |
| Cena de duelo principal | `levels/duel/main.tscn` + script `levels/duel/game.gd` | `Game` coordena projéteis, input mínimo e modos |
| Fundo decorativo | `ColorRect` 1920×864 | Nó `Background` |
| Linha visual do meio | Faixa **958–962** px em X (4 px) | `MidDivider` (só visual; o bloqueio é por código) |

### Chão, paredes e teto (física)

Tudo são `StaticBody2D` com `collision_mask = 0` (não recebem hits de outros corpos por máscara).

| Nó | Forma | Tamanho aprox. | Posição (centro do body) |
|----|--------|-----------------|---------------------------|
| `GroundBody` | Retângulo | **1920 × 84** | **(960, 822)** |
| `LeftWallBody` | Retângulo | **12 × 864** | **(6, 432)** |
| `RightWallBody` | Retângulo | **12 × 864** | **(1914, 432)** |
| `CeilingBody` | Retângulo | **1920 × 12** | **(960, 6)** |

O retângulo visual “chão” (`Ground` ColorRect) ocupa **y = 780 … 864**, alinhado ao topo do collider do solo (822 − 42 = 780 com meia-altura 42).

### Metades e “cerca” por jogador

O jogador não atravessa o meio da tela: em `_enforce_arena_half()` (`player.gd`) usa-se o retângulo do viewport, um ponto médio `mid = width / 2` e `arena_padding_x` (**36** px por padrão).

- **Player 1:** `x` clampado entre **36** e **`mid − 36`** → em 1920 px, aprox. **36 … 924**.
- **Player 2:** `x` clampado entre **`mid + 36`** e **1884** → aprox. **996 … 1884**.

Há uma faixa central (~**72** px) entre os limites dos dois lados; o divisor visual fica dentro dela. Se o personagem for empurrado para lá, a posição é corrigida e **`velocity.x` zera** para não atravessar.

---

## 2. Jogador (`Player` / `CharacterBody2D`)

### Hitbox e cena

Em `main.tscn`, os dois lutadores partilham a mesma geometria base:

| Elemento | Valor |
|----------|--------|
| `CollisionShape2D` | Retângulo **40 × 90** px |
| `collision_mask` | **3** (colide com as layers 1 e 2 da máscara — tipicamente mundo + projéteis, conforme layers do projeto) |
| `collision_layer` | Não definido na cena → **layer 1** por padrão do Godot |

Posições iniciais de exemplo na cena: P1 **(210, 672)**, P2 **(1710, 672)** (podem mudar em outros modos/respawns).

### Movimento horizontal (solo)

- Velocidade base: `move_speed` = **260** px/s.
- Input: eixo esquerdo/direito (`_get_move_axis`).
- Com **corrida** ativa e **só** a tecla “para a frente” (em direção ao adversário): multiplicador `sprint_speed_multiplier` = **1,42** → até **~369** px/s.
- **Corrida (todos):** após manter **só** “frente” durante `sprint_forward_hold_seconds` (**0,12** s por padrão em `Player`, `_update_sprint_from_forward_hold`). Dash, hover, stun ou deixar de cumprir “só frente” repõem o temporizador.
- **Dash (todos):** duplo toque **frente** ou **trás** dentro de `sprint_double_tap_window` (**0,50** s), via `Player._update_double_tap_forward_movement()` → `start_dash_with_direction(...)`. A tecla `p1_dash` / `p2_dash` **não** inicia dash.
- **Duplo toque estrito (todos):** entre o 1.º e o 2.º toque na mesma direção, qualquer outro input de locomoção **invalida** a janela: sentido oposto horizontal; eixo vertical de hover (`get_axis` hover_down/up) ao passar de neutro a ativo, ou `is_action_just_pressed` em hover; e **enquanto** o eixo vertical estiver acima do deadzone (W/S ou gatilho mantidos — evita D,W,D com W segurado no 2.º D). Com **controle**, o vertical de **locomoção** vem das ações `p*_move_up` / `p*_move_down` (stick esquerdo Y + D-pad ↑/↓), mapeadas em `Game._add_gamepad_mappings_for_player` — não usar só `get_joy_axis` nem só hover (gatilhos). Pulo, mira e skills **não** entram nesta regra. Implementação: `_double_tap_vertical_input_active`, `_vertical_locomotion_contaminates_double_tap`, `_update_double_tap_forward_movement` + `_invalidate_double_tap_chains_on_contaminant` em `Player`.

### Gravidade e pulo

| Export | Valor | Efeito |
|--------|--------|--------|
| `gravity_accel` | **1800** px/s² | Aplicada em `velocity.y` quando não está no chão e não está em hover/flutuação forçada |
| `jump_speed` | **650** | Impulso inicial para cima (`velocity.y = -jump_speed`) |
| `max_jumps` | **2** | Pulo + pulo duplo; ao aterrar, repõe contador |

No chão, se `velocity.y > 0`, é forcado a **0** (colagem ao solo).

### Dash (comportamento base)

Valores em `_get_dash_stats()` na classe `Player` (**comuns a todos** os duelistas, alinhados ao Esqueleto / Ongma):

| Campo | Valor |
|-------|--------|
| `speed` | **620** px/s |
| `duration` | **0,20** s |
| `cooldown` | **0,1** s após o dash terminar |
| `gravity_scale` | **0** (sem gravidade extra no ar durante o dash; ver clamp `vy` no código) |

Regras importantes:

- O início do dash passa por **`start_dash_with_direction(dir_sign)`**, que respeita `_can_start_dash()` (cooldown, carregar tiro, etc.).
- Durante o dash, **`velocity.x`** mantém-se fixo no sentido do dash; o cooldown de dash só começa quando `duration` expira.
- **Anti-encadeamento / anti-“flutuar”:** existe um intervalo mínimo `dash_min_gap_seconds` entre inícios de dash (aplica também quando o dash é cancelado por pulo/stun).
- **Dash no ar:** por padrão, só **1 dash no ar** por sequência aérea (`limit_air_dash_to_one`), reset ao tocar o chão.
- **Não** se pode iniciar dash se `input_enabled` for falso, se o cooldown ainda não acabou, ou se estiver a carregar tiro (`_is_charging`). O bloqueio por “skill de granada” (`_is_grenade_charging_active()`, ex. feixe do Esqueleto) só aplica se `_dash_blocked_by_grenade_skill()` for `true` na subclasse (no Esqueleto é `false`, para permitir dash durante o feixe).
- **Pulo durante o dash:** `_apply_jump_during_dash()` usa **`velocity = (v_dash + v_jump) × dash_jump_impulse_mul`** — por defeito **pouco Y** (`dash_jump_vertical_mul` baixo), **X reforçado** (`dash_jump_horizontal_scale`) e impulso global (`dash_jump_impulse_mul`) para sensação de **arco diagonal** forte (exports em `Player`).
- **Gravidade:** só se aplica `velocity.y += gravity_accel * gmul * delta` se `gmul > 0.0001` (evita somar gravidade com multiplicador ~0).
- Se `gravity_scale <= 0` durante dash **no ar**, após o bloco de pulo o código faz `velocity.y = minf(velocity.y, 0.0)` — remove componente de **queda** durante o dash, mantendo subida (`vy < 0`).
- Subclasses **não** sobrescrevem `_get_dash_stats()` — um único perfil de dash na base.

### Wall jump (comum)

- Implementado em `Player._try_special_air_jump()`: no ar, até **um** wall jump por sequência aérea (repõe ao aterrar), com deteção por `is_on_wall_only()` e raios laterais (`wall_detect_distance`, `wall_detect_vertical_offset`), impulso `wall_jump_horizontal_speed` / `wall_jump_vertical_speed`, graça `wall_jump_move_grace` no eixo horizontal e flash breve (`wall_jump_visual_duration`, `wall_jump_body_flash`).
- Não gasta `max_jumps`; cancela dash se estiver activo (com cooldown do dash).

### Stun, knockback e congelamento

| Export / estado | Valor / comportamento |
|------------------|------------------------|
| `hit_stun_time` | **0,14** s — `apply_knockback` aumenta `_control_lock_left` |
| `knockback_friction` | **2400** — durante stun, `velocity.x` aproxima-se de 0 com este atrito; em hover, o vetor inteiro é suavizado |
| `freeze_for` | Posição fixa, sem input, visual “gelado” até expirar |

### Vida e combate comum

- `max_hp` = **100** por padrão.
- Mira: ângulo limitado a **±85°** (`aim_limit_deg`); P1 mira com eixo “frente” **direita**, P2 **esquerda** (`_apply_mouse_aim`).
- Tiro carregado na base: `min_launch_speed` / `max_launch_speed` **420 / 900**, `max_charge_time` **1,0** s; prévia com `trajectory_points` **24** e `trajectory_step` **0,08** s.
- Recoil: acumula `_recoil_vel` e decai com `recoil_decay` **2400**; ver exports `recoil_*` em `player.gd`.

### Flutuação (mago / hover)

`start_hover_float(seconds)` define `_hover_float_left`. Enquanto ativo, o movimento pode ser **omnidirecional** (`_get_hover_move_vector`) com a mesma base `move_speed` e multiplicador de sprint; a gravidade normal não aplica da mesma forma que no solo.

---

## 3. Projéteis (visão global)

- A **flecha** base (`projectiles/arrow/arrow.tscn`) usa `CharacterBody2D`, **layer 2**, **mask 11**, colisor circular **raio 10**.
- O **spawn** e regras (gravidade no voo, ricochetes, cenas alternativas) estão centralizados em `Game._spawn_one_arrow` e sinais em `Player`. Flecha **sem** gravidade no voo para pistoleiro ou qualquer dono com `owner_player is EsqueletoPlayer` (Esqueleto, Ongma Epilef).
- Projéteis saem do **muzzle**; o corpo do jogador é apenas corrigido na **metade** da arena, não há “soft kill” por sair da tela para o jogador (flechas podem ser destruídas ao sair do viewport na própria lógica da `Arrow`).

---

## 4. Fluxo de um frame de combate (resumo)

1. **`Game._physics_process` / jogadores:** timers (cooldowns, dash, buffs).
2. **`Player._physics_process`:** congelamento → hover → dash ou movimento normal → recoil → gravidade → chão/pulos → opcional clamp vertical no dash → `move_and_slide()` → **`_enforce_arena_half()`** → **`_process_combat()`** (subclasse).
3. **`Game`** escuta `shoot_requested` / `shots_requested` e instancia projéteis na árvore da cena.

Assim, **movimento e cortes de arena** são sempre aplicados **depois** do deslocamento físico, garantindo que ninguém fica preso no meio nem nos cantos fora dos paddings.

---

## 5. Onde aprofundar

| Tema | Documento / código |
|------|---------------------|
| Baseline de personagem | [esqueleto_personagem_base.md](esqueleto_personagem_base.md) |
| Fichas e comparativo | [personagens/README.md](personagens/README.md), [comparativo_personagens_vs_esqueleto.md](comparativo_personagens_vs_esqueleto.md) |
| Input garantido no arranque | `Game._ensure_input_map()` em `game.gd` |
| Modo Vs / respawn | `Player.prepare_for_vs_round_respawn()` |

Ao mudar **padding**, **viewport** ou **colliders** do `main.tscn`, atualiza este ficheiro para o design e o código continuarem alinhados.
