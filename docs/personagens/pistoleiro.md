# Pistoleiro — ficha do personagem

Estrutura alinhada a [Esqueleto — personagem base (referência de design)](../esqueleto_personagem_base.md). Valores que não aparecem aqui coincidem com os exports de `Player` em `characters/player.gd`, salvo indicação em contrário.

**Script:** `characters/pistoleiro_player.gd` (`PistoleiroPlayer`).

**Controles (duelo):** tiro principal = mesmo mapa que os outros (P1 mouse, P2 **L**). **F** / **J** = granada instantânea (arremesso fixo em velocidade máxima ou detonar se já existir). **G** / **O** = especial (buff de sequência de 3 ataques). Ver `levels/duel/game.gd` (`_ensure_input_map`).

---

## 1. Física do projétil principal (tiro carregado + cadeia)

Usa `projectiles/arrow/arrow.tscn`. O `Game` trata pistoleiro como tiro **sem gravidade** e com **1 ricochete** por padrão nos spawns normais.

| Parâmetro | Valor | Notas |
|-----------|--------|--------|
| Velocidade min / max (carga) | **420** / **900** px/s | Herdado de `Player` (`min_launch_speed`, `max_launch_speed`, `max_charge_time` 1,0 s) |
| Gravidade no voo | **0** | `Game._spawn_one_arrow` |
| Ricochetes (tiro único normal) | **1** | Default em `Game` quando `bounces_override < 0` |
| Cadeia de pistola (passos 0→1→2) | Origem alterna `MuzzleTop` / `MuzzleBottom` / duplo tiro | `_fire_pistol_chain_shot`; passo 2 usa `shots_requested` com `bounces: 1` |
| Cooldown após disparo (cadeia) | **0,64** s | `pistol_chain_shoot_cooldown` |
| Reset da cadeia se parar de atirar | **1,5** s | `pistol_chain_reset_time` |
| Durante buff especial (tiros especiais) | **shoot_cooldown** da base (**0,4** s) | `_process_combat` ramo especial |
| Pré-visualização de trajetória | Gravidade **0** | `_preview_gravity_for_shot()` |

Granada: não é `Arrow`; velocidade de arremesso fixa **`grenade_max_throw_speed` = 960** px/s com ângulo `launch_angle_degrees + grenade_lob_angle_deg` (**+22°**). Cooldown skill **4,0** s. Gravidade só na prévia antiga (`grenade_trajectory_gravity` 1650 — hoje o arremesso é instantâneo sem carregar).

---

## 2. Recoil do projétil

| Situação | Força |
|----------|--------|
| Tiros simples da cadeia (passos 0 e 1) | `recoil_normal` (**170**) |
| Passo 2 (dois projéteis) | **recoil_normal × 1,12** (= **190,4**) |
| Especial — rajada multiplicada (índice 0) | **recoil_special** (**290**) |
| Especial — tiros com ricochete (índice 1) | **recoil_special** (**290**) |
| Especial — projétil grande concentrado (índice 2) | **recoil_special_big** (**480**) |

---

## 3. Tamanho do personagem

Igual ao baseline da arena: ver secção **3** do [documento do Esqueleto](../esqueleto_personagem_base.md) (`main.tscn`, **40×90** px).

---

## 4. Skills (Pistoleiro)

### 4.1 Buff especial (tecla especial)

| Parâmetro | Valor |
|-----------|--------|
| Duração do buff | **8,0** s | `special_buff_duration` |
| Cooldown ao ativar | **special_cooldown** do `Player` (**3,0** s) |
| Sequência | **3** ataques especiais distintos (`_special_attack_index` 0..2) |
| Ataque 0 | 3 ângulos por boca (−4°, 0°, +4°) × cada posição de muzzle; `bounces: 0` | `special_multi_spread_deg` **4** |
| Ataque 1 | Até 3 tiros das posições de muzzle; `bounces: special_ricochet_bounces` (**1**) | |
| Ataque 2 | Carga **1,0** s (`special_big_charge_time`) — bloqueia pulo durante concentração | |
| Projétil grande | Velocidade **max_launch_speed × 1,25** (= **1125** px/s), `size` **2,8**, `damage` **45**, `bounces` **1**, spawn `muzzle + dir × (18 × size)` | |

### 4.2 Granada

| Parâmetro | Valor |
|-----------|--------|
| Cooldown | **4,0** s | `grenade_skill_cooldown` |
| Arremesso | Velocidade fixa **960** px/s (`grenade_max_throw_speed`), ângulo com **+22°** (`grenade_lob_angle_deg`) | Tecla: mesmo slot que “granada” no input map |

---

## 5. Dash

| Parâmetro | Valor |
|-----------|--------|
| Velocidade | **520** px/s |
| Duração | **0,28** s |
| Cooldown | **1,05** s |
| Gravidade durante dash | **0,55** × |

---

## 6. Pulo e pulo duplo

Sem overrides no script — iguais ao `Player` / baseline Esqueleto (`jump_speed` **650**, `max_jumps` **2**, `gravity_accel` **1800**).

**Nota:** pulo bloqueado enquanto `_is_special_concentrating` (especial grande).

---

## 7. Corrida (sprint)

Sem overrides — igual ao sprint descrito na [secção 7 do baseline do Esqueleto](../esqueleto_personagem_base.md) (ramo “outros personagens”, não o kit duplo‑toque‑dash).

---

## 8. Blueprint / diferenças úteis

| Parâmetro | Valor |
|-----------|--------|
| Escudo | **4** cargas | `_max_shield_charges` |
| Recarga do escudo | **4,25** s | `_shield_reload_seconds` |

---

## 9. Arquivos

- `characters/pistoleiro_player.gd`
- `levels/duel/game.gd` — spawn `Arrow` com `g=0`, `bounces=1` por padrão
- `projectiles/grenade/` — granada
