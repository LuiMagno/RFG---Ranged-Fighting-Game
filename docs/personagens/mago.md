# Mago — ficha do personagem

Estrutura alinhada a [Esqueleto — personagem base (referência de design)](../esqueleto_personagem_base.md). Valores omitidos coincidem com `Player` em `characters/player.gd`.

**Script:** `characters/mago_player.gd` (`MagoPlayer`).

**Controles (duelo):** “tiro” principal carrega míssil teleguiado. **F** / **J** = gelo (lançar ou detonar). **C** (P1) / **Y** (P2) = levitação (`p1_mage_float` / `p2_mage_float`). **G** / **O** = segurar para carregar **orbe** gravitacional (soltar após limiar dispara). Ver `levels/duel/game.gd`.

---

## 1. Física do projétil principal (míssil teleguiado)

O `Game` instancia **`HomingMissile`** (`projectiles/homing_missile/`), não a flecha balística padrão para disparos do mago.

| Parâmetro | Valor | Notas |
|-----------|--------|--------|
| Velocidade (carga) | **360** → **520** px/s | `missile_min_speed`, `missile_max_speed` |
| Tempo de carga | **0,85** s | `missile_charge_time` (barra usa este tempo, não `max_charge_time` do `Player`) |
| Gravidade no voo | **0** | `HomingMissile.setup` força `gravity_accel = 0`, `bounces_left = 0` |
| Homing (export no míssil) | Ex.: **120** °/s de rotação, lead **0,06** s, `homing_min_speed` **340**, etc. | `homing_missile.gd` |
| Recoil no disparo | **recoil_normal × 0,82** (= **139,4**) | `_process_combat` mago |

Cooldown após tiro: **`shoot_cooldown`** do `Player` (**0,4** s por defeito).

---

## 2. Recoil do projétil

| Situação | Força |
|----------|--------|
| Tiro principal (míssil) | **139,4** (`recoil_normal × 0,82`) |
| Orbe (ao soltar) | **lerp(140, 260, t_orb)** conforme carga | `_process_combat` |

---

## 3. Tamanho do personagem

Igual ao baseline — [Esqueleto sec. 3](../esqueleto_personagem_base.md#3-tamanho-do-personagem).

---

## 4. Skills (Mago)

### 4.1 Gelo (F / J)

| Parâmetro | Valor |
|-----------|--------|
| Cooldown | **6,0** s | `ice_skill_cooldown` |
| Velocidade de arremesso | **420** px/s | `ice_throw_speed` |
| Segundo uso | Detona gelo ativo | `mage_ice_detonate_requested` |

### 4.2 Levitação (C / Y)

| Parâmetro | Valor |
|-----------|--------|
| Duração | **3,2** s | `float_duration` (`start_hover_float`) |
| Cooldown | **6,0** s | `float_skill_cooldown` |

### 4.3 Orbe gravitacional (segurar G / O)

| Parâmetro | Valor |
|-----------|--------|
| Carga máxima | **1,25** s | `orb_max_charge_time` |
| Limiar para contar como “carregado” | **0,42** s | `orb_hold_threshold` |
| Cooldown após disparo | **5,0** s | `orb_skill_cooldown` |
| Visual no muzzle | Escala **0,32** → **1,15** | `orb_visual_scale_min` / `orb_visual_scale_max` |
| Recoil ao soltar | Ver secção 2 | Velocidade auxiliar no recoil: **420** px/s em `_compute_launch_velocity` para o impulso |

---

## 5. Dash

| Parâmetro | Valor |
|-----------|--------|
| Velocidade | **760** px/s |
| Duração | **0,16** s |
| Cooldown | **1,0** s |
| Gravidade durante dash | **0,42** × |

---

## 6. Pulo e pulo duplo

Sem overrides no script — igual ao baseline. **Nota:** carregar orbe (G/O) pode bloquear tiro carregado enquanto `_is_orb_charge_active()`; levitar/gelo respeitam `_is_orb_charge_active()` para não disparar por cima.

---

## 7. Corrida (sprint)

Sem overrides — igual ao baseline.

---

## 8. Blueprint

Sem escudo extra (`_max_shield_charges` = 0 na base, não sobrescrito no mago).

---

## 9. Arquivos

- `characters/mago_player.gd`
- `levels/duel/game.gd` — `want_homing`, gelo, orbe
- `projectiles/homing_missile/`, `ice_missile/`, `gravity_orb/`
