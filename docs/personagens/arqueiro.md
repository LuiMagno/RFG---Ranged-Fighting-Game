# Arqueiro — ficha do personagem

Estrutura alinhada a [Esqueleto — personagem base (referência de design)](../esqueleto_personagem_base.md). Valores omitidos coincidem com `Player` em `characters/player.gd`.

**Script:** `characters/arqueiro_player.gd` (`ArqueiroPlayer`).

**Controles (duelo):** tiro com carga = P1 rato / P2 **L**. Buff de espinhos: **F** (`p1_archer_spike`) / **U** (`p2_archer_spike`). Especial **G** / **O**: sem buff ativo entra no fluxo “flecha portadora + split”; com tiros de espinho buffados pode armar leque de 5 (`spike_volley`). Ver `levels/duel/game.gd`.

---

## 1. Física do projétil principal (tiro carregado)

Usa `Arrow` por defeito. O `Game` **não** aplica a regra pistoleiro/esqueleto: gravidade no voo = **`arrow.gravity_accel`** (**1200** px/s²), ricochetes **0**.

| Parâmetro | Valor | Notas |
|-----------|--------|--------|
| Velocidade min / max (carga) | **420** / **900** px/s | `Player` |
| Tempo de carga | **1,0** s | `max_charge_time` |
| Flecha “portadora” (split) | Flag `archer_split`; pode aumentar tamanho mínimo no spawn | `Game._spawn_one_arrow` |
| Espinhos (`spike_shot` / volley) | Cena `ArcherSpike`, gravidade **1200** | `archer_spike.gd` |

---

## 2. Recoil do projétil

Todos os disparos listados usam **`recoil_normal` (170)** no código atual (`_apply_recoil` com `recoil_normal`).

---

## 3. Tamanho do personagem

Igual ao baseline — [Esqueleto sec. 3](../esqueleto_personagem_base.md#3-tamanho-do-personagem) (**40×90** px em `main.tscn`).

---

## 4. Skills (Arqueiro)

### 4.1 Buff de espinhos (F / U)

| Parâmetro | Valor |
|-----------|--------|
| Cooldown do buff | **5,5** s | `archer_spike_buff_cooldown` |
| Efeito | Próximos **3** disparos normais disparam projétil `spike_shot` (espinho) em vez de flecha padrão | |
| Combo G | Com buff ativo, **G** arma leque de **5** espinhos no próximo tiro (`spike_volley`) | |

### 4.2 Fluxo especial (flecha no ar + split)

| Fase | Descrição |
|------|-----------|
| 0 → 1 | Tecla especial: entra em modo buff de split (`archer_phase` 1) |
| 1 → 2 | Próximo disparo solta flecha com `archer_split`; segundo clique/atirar pede `archer_split_now_requested` |
| 2 → 0 | Após split manual ou cancelamento | |

### 4.3 Escudo

| Parâmetro | Valor |
|-----------|--------|
| Cargas | **3** |
| Recarga | **4,0** s |
| Refletir flecha | Cura **+6** HP (cap `max_hp`); `shield_reflect_heal` |

### 4.4 Fragmentação / leque

| Parâmetro | Valor |
|-----------|--------|
| Spread típico no split | **7°** (`archer_split_spread_deg`, até 22° no inspector); usado em `Game` ao fragmentar / volley |

---

## 5. Dash

| Parâmetro | Valor |
|-----------|--------|
| Velocidade | **980** px/s |
| Duração | **0,1** s |
| Cooldown | **0,8** s |
| Gravidade durante dash | **0,32** × |

---

## 6. Pulo e pulo duplo

Sem overrides — igual ao baseline Esqueleto (`Player`).

---

## 7. Corrida (sprint)

Sem overrides — igual ao baseline.

---

## 8. Blueprint / HUD

Sinal `archer_spike_hud_changed` para tiros de espinho restantes e se o volley G está armado.

---

## 9. Arquivos

- `characters/arqueiro_player.gd`
- `levels/duel/game.gd` — split, `ArcherSpike`, carrier
- `projectiles/archer_spike/`
