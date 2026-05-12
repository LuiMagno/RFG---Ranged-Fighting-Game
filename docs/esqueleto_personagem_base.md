# Esqueleto — personagem base (referência de design)

**Documentos relacionados:** arena, movimento, dash e física comuns em [sistemas_core_arena_e_movimento.md](sistemas_core_arena_e_movimento.md) · fichas por personagem em [personagens/](personagens/) · comparativo **vs.** este baseline em [comparativo_personagens_vs_esqueleto.md](comparativo_personagens_vs_esqueleto.md).

Este documento consolida os valores do **Esqueleto** (`EsqueletoPlayer` / `characters/esqueleto_player.gd`) e tudo que ele **herda** de `Player` (`characters/player.gd`), além de regras de spawn em `Game` (`levels/duel/game.gd`). O esqueleto usa a mesma cena física/visual que os outros duelistas em `levels/duel/main.tscn` (o script é trocado em runtime via `RunConfig`).

## Política de design (baseline de personagens)

Os números e comportamentos do **Esqueleto** definem o **padrão de referência** do projeto para duelo: velocidades de tiro, recoil, dash (duplo toque frente/trás — **comum a todos** em `Player`), movimento, pulo, regras de **dash no ar** e **anti-encadeamento**, **corrida pós-dash** (opcional), wall jump na base, dimensão do corpo e relação com o `Game` (spawn de projéteis, gravidade no voo, etc.). A **corrida por só manter “frente”** (`sprint_mechanic_enabled`) existe na base mas está **desligada** por defeito; o pacing actual privilegia dash + **sprint após dash para a frente**. Ao equilibrar ou criar conteúdo novo, compara-se primeiro com esta folha antes de afastar valores “sem motivo”.

**Regra de trabalho:** daqui em diante, **todo personagem novo parte conceitual e numericamente do Esqueleto** — ou seja, copia-se o perfil do esqueleto (ou o script `esqueleto_player.gd` como ponto de partida) e **só depois** se alteram stats, skills e exceções de spawn à medida que o design do arquétipo exige. Personagens já existentes (pistoleiro, arqueiro, mago) continuam válidos, mas **evoluções e novos lutadores** devem documentar explicitamente o que mudou em relação a este baseline, para manter coerência de pacing e leitura de jogo.

**Família Esqueleto no código:** qualquer nó com script que **é** `EsqueletoPlayer` (inclui **Ongma Epilef**, `extends EsqueletoPlayer`) entra nas mesmas regras de `Game` que o esqueleto para flecha reta e HUD do triplo — ver `owner_player is EsqueletoPlayer` em `levels/duel/game.gd`. Ficha do laboratório: [personagens/ongma_epilef.md](personagens/ongma_epilef.md).

---

**Controles (duelo, após `_ensure_input_map` em `game.gd`):**

No Vs, **só um** jogador pode usar **teclado+mouse**; o outro usa **controle**. Quem estiver em teclado+mouse usa o mesmo layout **WASD + mouse** (ações `p1_*` ou `p2_*` conforme o lado, mas mesmas teclas físicas).

| Ação | Teclado+mouse (`p1_*` ou `p2_*`) | Controle (RB / X / Y etc. em `p1_*` ou `p2_*`) |
|------|-----------------------------------|-----------------------------------------------|
| Tiro principal (carregar + soltar) | Botão esquerdo do mouse (`*_shoot`) | **RB** |
| Skill “raio” (carregar + soltar) | **F** (`*_grenade`) | **X** |
| Skill “triplo” (arma o próximo disparo) | **G** (`*_special`) | **Y** |
| **Dash (todos)** | Duplo toque **D**→**D** (frente); duplo **A**→**A** (trás), janela `sprint_double_tap_window`. A tecla `*_dash` **não** inicia dash. | Duplo toque frente/trás no stick; vertical de locomoção em `p*_move_up` / `p*_move_down` entra nas regras de duplo toque estrito (`game.gd` + `Player`). |

---

## 1. Física do projétil principal (tiro carregado)

O tiro usa a cena `projectiles/arrow/arrow.tscn` (classe `Arrow`). Para o esqueleto, o jogo força **gravidade zero** na flecha (trajetória reta, como no pistoleiro).

| Parâmetro | Valor | Onde está |
|-----------|--------|-----------|
| Velocidade mínima (solto na hora) | **420** px/s | `Player.min_launch_speed` |
| Velocidade máxima (carga completa) | **900** px/s | `Player.max_launch_speed` |
| Tempo máximo de carga | **1,0** s | `Player.max_charge_time` |
| Velocidade efetiva | `lerp(min_launch_speed, max_launch_speed, t)` com `t = charge_time / max_charge_time` | `EsqueletoPlayer._process_combat` |
| Gravidade no voo | **0** | `Game._spawn_one_arrow`: pistoleiro **ou** `owner_player is EsqueletoPlayer` (Esqueleto, Ongma Epilef, …) → `g = 0` |
| Ricochetes padrão | **0** | `Game._spawn_one_arrow`: não-pistoleiro → `bounces = 0` |
| Dano padrão (sem override) | **20** | `Arrow.damage` (`arrow.gd`) |
| Knockback ao acertar | **520** horizontal, **220** para cima | `Arrow.knockback_x`, `knockback_up` |
| Tamanho visual/colisor base da flecha | Corpo ~28×6 px (polígono); colisor círculo **raio 10** | `arrow.tscn` + `arrow.gd` |
| Cooldown após soltar o tiro | **≥ 1,0** s | `EsqueletoPlayer.MIN_SHOOT_COOLDOWN_S`; em `_ready`, `shoot_cooldown = max(1.0, shoot_cooldown)` |
| Limite de mira (elevación) | **±85°** em relação ao eixo “para frente” | `Player.aim_limit_deg` |
| Pré-visualização da trajetória | **24** pontos, passo **0,08** s | `Player.trajectory_points`, `trajectory_step` |
| Pré-visualização com gravidade | **0** (linha reta) | `EsqueletoPlayer._preview_gravity_for_shot()` |

---

## 2. Recoil do projétil

Base em `Player`; o esqueleto aplica multiplicadores em situações específicas.

| Parâmetro | Valor | Notas |
|-----------|--------|--------|
| `recoil_normal` | **170** | Tiro simples (um projétil) |
| `recoil_special` | **290** | Export na base; o esqueleto não usa diretamente no script atual |
| `recoil_special_big` | **480** | Usado na skill “raio” com fator |
| `recoil_y_factor` | **0,25** | Componente vertical do recoil |
| `recoil_decay` | **2400** | Quão rápido o vetor extra de recoil decai |
| Tiro triplo | **recoil_normal × 1,12** (= **190,4**) | Três projéteis paralelos |
| Skill raio (beam) | **recoil_special_big × 0,82** (= **393,6**) | `_fire_beam` |

Implementação: `_apply_recoil(shot_velocity, strength)` em `player.gd` (impulso oposto à velocidade do tiro, com `y` atenuado).

---

## 3. Tamanho do personagem

Valores da instância em `main.tscn` (válidos para qualquer script de `Player`, incluindo esqueleto).

| Elemento | Valor |
|----------|--------|
| **CollisionShape2D** | `RectangleShape2D` **40 × 90** px |
| **Body** (`Polygon2D`) | Retângulo **40 × 90** px (vértices approx. −20,−45 … 20,45) |
| **Bow** (visual) | Barra ~**42 × 6** px, deslocada lateralmente (P1: +18 em x; P2 espelhado) |
| **Muzzle** | P1: **(35, −10)** relativo ao corpo; P2: **(−35, −10)** |

`Player` não aplica escala global ao `CharacterBody2D` por script; hitbox = **40×90**.

---

## 4. Skills (Esqueleto)

### 4.0 Integração com a base `Player` (hooks)

| Método / sinal | Comportamento no Esqueleto |
|----------------|----------------------------|
| `_is_grenade_charging_active()` | `true` enquanto o feixe está a carregar (`_beam_charging`) — usado na base para UI/bloqueios que dependem de “skill de granada” a carregar. |
| `_dash_blocked_by_grenade_skill()` | **`false`** — o dash **não** é bloqueado pelo carregamento do feixe (diferente do default da base). |
| `_preview_gravity_for_shot()` | **`0.0`** — pré-visualização de trajetória recta. |

### 4.1 Triplo (arma o próximo disparo do “tiro principal”)

| Parâmetro | Valor |
|-----------|--------|
| Cooldown da skill | **5,0** s | `triple_shot_cooldown` |
| Uso | Um disparo: ao soltar o carregamento normal, nascem **3** flechas com a **mesma** velocidade `v0` |
| Espaçamento lateral entre raias | **10,0** px | `triple_parallel_lane_spacing` (direção perpendicular a `v0`) |
| HUD | `special_buff_changed(true, 1, 0)` ao armar; ao disparar, desarma e emite com usos 0 |

### 4.2 “Raio” / projétil grande (segurar tecla de granada e soltar)

Na prática é um disparo único via `shots_requested` com flags de dano/tamanho/gravidade.

| Parâmetro | Valor |
|-----------|--------|
| Cooldown | **4,25** s | `beam_skill_cooldown` |
| Tempo máximo de carga | **0,65** s | `beam_max_charge_time` |
| Escala (tamanho) | `lerp(1.85, 3.45, t)` | `beam_min_scale` … `beam_max_scale` |
| Dano | **36** | `beam_damage` |
| Velocidade | `lerp(min_launch × 1.05, max_launch × 1.42, t)` | `beam_speed_mul_min` / `beam_speed_mul_max` → **441** … **1278** px/s nos extremos |
| Gravidade do projétil | **0** | payload em `_fire_beam` |
| Ricochetes | **0** | `bounces: 0` |
| Posição de spawn | `muzzle.global_position + dir × (22.0 × size)` | offset ao longo da mira |
| Tiro normal durante carga do feixe | Ramo de carregar `*_shoot` **não** corre enquanto `_beam_charging` | `EsqueletoPlayer._process_combat` (prioridade ao feixe) |

---

## 5. Dash

**Activação** do dash (duplo toque frente/trás), **números do dash** (`_get_dash_stats()` na base), **pulo durante o dash** e **wall jump** estão em `Player`.

| Parâmetro | Valor (todos os duelistas) |
|-----------|----------------------------|
| Velocidade | **620** px/s |
| Duração | **0,20** s |
| Cooldown após terminar | **0,1** s |
| `gravity_scale` durante o dash | **0** (sem aceleração de gravidade; no ar o `Player` também corta queda residual `vy > 0` enquanto o dash está activo) |

**No ar:** com `gravity_scale` **0**, durante o dash não há aceleração gravitacional; ao terminar o dash, a queda volta ao normal.

**Regras adicionais (todos, `Player`):**

- **`dash_min_gap_seconds`:** intervalo mínimo entre **inícios** de dash (inclui cancelar dash por pulo ou stun), para evitar encadear dash→pulo→dash.
- **`limit_air_dash_to_one`:** por defeito, **no máximo um dash no ar** por sequência aérea até tocar **chão** ou **parede**; o **cooldown** do dash (`cooldown` em `_get_dash_stats()` + o gap acima) continua a aplicar-se.
- **Corrida pós-dash:** ao **terminar** um dash **para a frente** (P1: sentido +1; P2: −1), abre-se uma janela `post_dash_sprint_window_seconds`; se o jogador **só** segurar “frente” nessa janela, activa-se sprint (`post_dash_sprint_enabled`). Dash **para trás** não abre essa janela.
- **Feixe do Esqueleto:** `_dash_blocked_by_grenade_skill()` devolve **false** — permite dash durante o carregamento do feixe; o bloqueio genérico por “granada a carregar” na base não aplica da mesma forma aqui.

**Pulo durante o dash:** `Player._apply_jump_during_dash()` — **`velocity = (v_dash + v_jump) × dash_jump_impulse_mul`**, com `v_dash` / `v_jump` definidos pelos exports `dash_jump_vertical_mul`, `dash_jump_horizontal_scale`, `dash_jump_impulse_mul` (arco diagonal forte vs. pulo normal).

---

## 6. Pulo e pulo duplo

Herdado de `Player` para o pulo **fora** do dash e wall jump.

| Parâmetro | Valor |
|-----------|--------|
| `jump_speed` | **700** (valor por defeito em `Player`; impulso inicial para cima; eixo Y negativo em Godot 2D) |
| `max_jumps` | **2** (pulo + pulo duplo) |
| `gravity_accel` | **1800** px/s² |
| Reset de pulos | Ao tocar o chão (`is_on_floor()`), `_jumps_left = max_jumps` |

Exports em `Player` para pulo no dash: `dash_jump_vertical_mul`, `dash_jump_horizontal_scale`, `dash_jump_impulse_mul` (secção 5).

---

## 7. Corrida (sprint), corrida pós-dash e duplo toque

- **Dash:** duplo toque frente ou trás dentro de `sprint_double_tap_window` (`Player._update_double_tap_forward_movement`); duplo toque **estrito** (invalidação por input vertical / stick — ver [sistemas_core_arena_e_movimento.md](sistemas_core_arena_e_movimento.md)).
- **Corrida “clássica” (só segurar frente):** `sprint_mechanic_enabled` (**false** por defeito). Quando **true**, `sprint_forward_hold_seconds` + `_update_sprint_from_forward_hold` activam `_sprint_active`; `start_dash_with_direction` chama `_interrupt_sprint()`.
- **Corrida pós-dash:** `post_dash_sprint_enabled` (**true** por defeito). Só após dash **para a frente**; janela `post_dash_sprint_window_seconds`. Velocidade com `sprint_speed_multiplier` (por defeito **1,55** sobre `move_speed`).
- **Indicador visual de corrida:** `sprint_indicator_*` — anel (`Polygon2D`) sob o personagem com pulso quando `_is_sprint_speed_boost_active()`.

| Parâmetro | Valor (`Player`, defeitos actuais) |
|-----------|-------------------------------------|
| `move_speed` (base) | **260** px/s |
| `sprint_double_tap_window` | **0,50** s (janela do dash duplo) |
| `sprint_mechanic_enabled` | **false** (corrida por manter frente desligada para testes / pacing) |
| `sprint_forward_hold_seconds` | **0,12** s (só usado se `sprint_mechanic_enabled`) |
| `post_dash_sprint_enabled` | **true** |
| `post_dash_sprint_window_seconds` | **0,18** s |
| `sprint_speed_multiplier` | **1,55** |
| `dash_min_gap_seconds` | **0,06** s (entre inícios de dash) |
| `limit_air_dash_to_one` | **true** |
| Condição sprint activa | Só tecla “frente” sem a contrária (`_is_holding_forward_only`); visual corpo/arco com `sprint_visual_*` + indicador opcional |

No **respawn Vs**, `EsqueletoPlayer._extra_reset_for_vs_round()` repõe `_last_forward_tap_time_s` e `_last_back_tap_time_s` para evitar dash acidental logo ao entrar no round.

---

## 8. Blueprint / valores úteis para outros personagens

Além dos blocos acima, estes exports de `Player` costumam ser o “contrato” comum da arena:

| Parâmetro | Valor | Uso típico |
|-----------|--------|------------|
| `max_hp` | **100** | Vida |
| `hit_stun_time` | **0,14** s | Stun após knockback |
| `knockback_friction` | **2400** | Deslize horizontal ao perder controle |
| `special_cooldown` | **3,0** s | Cooldown genérico na base (o esqueleto usa timers próprios para triplo/raio) |
| `projectile_gravity_accel` | **1200** | Usado na prévia e por outros personagens; esqueleto zera a prévia e o spawn |
| `arena_padding_x` | **36** | Limite horizontal da metade da arena |

Camadas (duelo): jogadores `collision_mask = 3`; flechas em `arrow.tscn` com `collision_layer = 2` e `collision_mask = 11` (inclui layer de jogadores).

---

## 9. Referência rápida de arquivos

- `characters/esqueleto_player.gd` — triplo, raio, cooldown mínimo de tiro, reset de toques no Vs.
- `characters/ongma_epilef_player.gd` — laboratório; `extends EsqueletoPlayer`.
- `characters/player.gd` — movimento, mira, recoil, pulo, dash (duplo toque, gap mínimo, dash no ar com reset em chão/parede), `_get_dash_stats()`, wall jump, `start_dash_with_direction`, pulo no dash (vector composto), corrida clássica opcional, **corrida pós-dash**, indicador visual de sprint, gravidade/clamp no dash, duplo toque estrito (teclado + `move_up`/`move_down` no comando).
- `levels/duel/game.gd` — flecha com `g = 0` se pistoleiro **ou** `owner_player is EsqueletoPlayer`; HUD do triplo para `left_player/right_player is EsqueletoPlayer`; spawn de `Arrow`.
- `projectiles/arrow/arrow.gd` + `arrow.tscn` — física/dano/tamanho base do projétil.
- `levels/duel/main.tscn` — dimensões do corpo, colisor, muzzle, UI de carga/trajetória.

Se alterar um valor de balanceamento, prefira manter **exports** no script ou propriedades na cena e atualizar este documento na mesma alteração para o esqueleto continuar servindo de referência única.
