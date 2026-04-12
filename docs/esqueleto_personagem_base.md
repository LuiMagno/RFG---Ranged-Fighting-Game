# Esqueleto — personagem base (referência de design)

**Documentos relacionados:** fichas por personagem em [personagens/](personagens/) · comparativo **vs.** este baseline em [comparativo_personagens_vs_esqueleto.md](comparativo_personagens_vs_esqueleto.md).

Este documento consolida os valores do **Esqueleto** (`EsqueletoPlayer` / `characters/esqueleto_player.gd`) e tudo que ele **herda** de `Player` (`characters/player.gd`), além de regras de spawn em `Game` (`levels/duel/game.gd`). O esqueleto usa a mesma cena física/visual que os outros duelistas em `levels/duel/main.tscn` (o script é trocado em runtime via `RunConfig`).

## Política de design (baseline de personagens)

Os números e comportamentos do **Esqueleto** definem o **padrão de referência** do projeto para duelo: velocidades de tiro, recoil, dash, movimento, pulo, corrida, dimensão do corpo e relação com o `Game` (spawn de projéteis, gravidade no voo, etc.). Ao equilibrar ou criar conteúdo novo, compara-se primeiro com esta folha antes de afastar valores “sem motivo”.

**Regra de trabalho:** daqui em diante, **todo personagem novo parte conceitual e numericamente do Esqueleto** — ou seja, copia-se o perfil do esqueleto (ou o script `esqueleto_player.gd` como ponto de partida) e **só depois** se alteram stats, skills e exceções de spawn à medida que o design do arquétipo exige. Personagens já existentes (pistoleiro, arqueiro, mago) continuam válidos, mas **evoluções e novos lutadores** devem documentar explicitamente o que mudou em relação a este baseline, para manter coerência de pacing e leitura de jogo.

---

**Controles (duelo, após `_ensure_input_map` em `game.gd`):**

| Ação | Player 1 | Player 2 |
|------|-----------|-----------|
| Tiro principal (carregar + soltar) | Botão esquerdo do rato (`p1_shoot`) | **L** (`p2_shoot`) |
| Skill “raio” (carregar + soltar) | **F** (`p1_grenade`) | **J** (`p2_grenade`) |
| Skill “triplo” (arma o próximo disparo) | **G** (`p1_special`) | **O** (`p2_special`) |
| Dash | **Shift** esquerdo | **Shift** direito |

---

## 1. Física do projétil principal (tiro carregado)

O tiro usa a cena `projectiles/arrow/arrow.tscn` (classe `Arrow`). Para o esqueleto, o jogo força **gravidade zero** na flecha (trajetória reta, como no pistoleiro).

| Parâmetro | Valor | Onde está |
|-----------|--------|-----------|
| Velocidade mínima (solto na hora) | **420** px/s | `Player.min_launch_speed` |
| Velocidade máxima (carga completa) | **900** px/s | `Player.max_launch_speed` |
| Tempo máximo de carga | **1,0** s | `Player.max_charge_time` |
| Velocidade efetiva | `lerp(min_launch_speed, max_launch_speed, t)` com `t = charge_time / max_charge_time` | `EsqueletoPlayer._process_combat` |
| Gravidade no voo | **0** | `Game._spawn_one_arrow`: pistoleiro **ou** esqueleto → `g = 0` |
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
| Pulo durante carga | **Bloqueado** enquanto carrega o raio | `_allow_jump_while_concentrating()` |

---

## 5. Dash

O esqueleto **sobrescreve** `_get_dash_stats()` (a base usa outros números).

| Parâmetro | Esqueleto | `Player` (default) |
|-----------|------------|---------------------|
| Velocidade | **620** px/s | 700 |
| Duração | **0,20** s | 0,18 |
| Cooldown após terminar | **0,92** s | 0,9 |
| Multiplicador de gravidade durante o dash | **0,46** | 0,42 |

Durante o dash, `velocity.x` fica fixo no sentido do dash; a gravidade vertical é multiplicada por `gravity_scale` acima.

---

## 6. Pulo e pulo duplo

Herdado de `Player` (sem override no esqueleto).

| Parâmetro | Valor |
|-----------|--------|
| `jump_speed` | **650** (impulso inicial para cima; eixo Y negativo em Godot 2D) |
| `max_jumps` | **2** (pulo + pulo duplo) |
| `gravity_accel` | **1800** px/s² |
| Reset de pulos | Ao tocar o chão (`is_on_floor()`), `_jumps_left = max_jumps` |

---

## 7. Corrida (sprint por duplo toque “para frente”)

Herdado de `Player`.

| Parâmetro | Valor |
|-----------|--------|
| `move_speed` (base) | **260** px/s |
| `sprint_double_tap_window` | **0,28** s |
| `sprint_speed_multiplier` | **1,42** → velocidade horizontal **~369** px/s com sprint ativo |
| Condição | Duplo toque na tecla **para frente** (em direção ao adversário); sprint mantém-se só enquanto **só** a tecla “frente” está pressionada (sem contrário) |
| Visual | `sprint_visual_body_mult`, `sprint_visual_bow_mult` (multiplicam `modulate`) |

O dash **interrompe** a corrida (`_interrupt_sprint()`).

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

- `characters/esqueleto_player.gd` — lógica exclusiva (dash, triplo, raio, cooldown mínimo de tiro).
- `characters/player.gd` — movimento, mira, recoil, pulo, sprint, dash genérico.
- `levels/duel/game.gd` — `g = 0` e `bounces` para esqueleto; spawn de `Arrow`.
- `projectiles/arrow/arrow.gd` + `arrow.tscn` — física/dano/tamanho base do projétil.
- `levels/duel/main.tscn` — dimensões do corpo, colisor, muzzle, UI de carga/trajetória.

Se alterar um valor de balanceamento, prefira manter **exports** no script ou propriedades na cena e atualizar este documento na mesma alteração para o esqueleto continuar servindo de referência única.
