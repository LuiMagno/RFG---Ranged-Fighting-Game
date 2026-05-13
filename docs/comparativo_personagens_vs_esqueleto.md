# Comparativo: personagens vs. Esqueleto (baseline)

O **Esqueleto** é a referência de design; os valores “Esqueleto” abaixo resumem o que está em [esqueleto_personagem_base.md](esqueleto_personagem_base.md). Fichas detalhadas por personagem: [personagens/](personagens/). **Ongma Epilef** herda o esqueleto (`extends EsqueletoPlayer`); para comparativo numérico coincide com o baseline até haver overrides — ver [personagens/ongma_epilef.md](personagens/ongma_epilef.md).

**Legenda:** “=” igual ao baseline herdado de `Player` ou à mesma cena; “≠” diferente.

---

## Esqueleto (referência)

| Área | Valor resumido |
|------|----------------|
| Projétil principal | `Arrow`; velocidade **420–900**; carga **1,0** s; **g = 0**; **0** ricochetes; cooldown **≥ 1,0** s |
| Recoil tiro simples | **170** |
| Dash | **620** px/s, **0,20** s, CD **0,1** s, **`gravity_scale` 0** (sem queda durante o dash no ar); activação por **duplo toque** frente/trás (todos os duelistas) |
| Escudo | **Nenhum** (0 cargas) |
| Movimento / pulo | `move_speed` **260**, `jump_speed` **650**, `max_jumps` **2**; sprint ao **manter só frente** (`sprint_forward_hold_seconds`); duplo toque = **dash**; **wall jump** na base |
| Corpo (hitbox) | **40×90** px |
| Skills | Triplo (CD **5** s) + raio carregável (CD **4,25** s, dano **36**, escala **1,85–3,45**) |

---

## Pistoleiro vs. Esqueleto

| Tópico | Esqueleto | Pistoleiro | Notas |
|--------|-----------|------------|--------|
| Cena do projétil principal | `Arrow` | `Arrow` | = |
| Gravidade no voo | **0** | **0** | = regra `Game` |
| Ricochetes (tiro normal único) | **0** | **1** | ≠ mais “tanque” de ricochete |
| Velocidade min / max carga | 420 / 900 | 420 / 900 | = exports `Player` |
| Tempo de carga | 1,0 s | 1,0 s | = |
| Cooldown após atirar | **≥ 1,0** s | **0,64** s (cadeia) / **0,4** s (durante buff especial) | ≠ cadência mais rápida |
| Padrão de tiro | 1 projétil (feixe ou buff de velocidade no carregado) | Cadeia 3 passos (top / bottom / duplo) | ≠ identidade |
| Recoil tiro simples | 170 | 170 (passos 0–1); **190,4** passo 2 | ≈ |
| Skills | Triplo + raio | Buff 3 ataques + granada | ≠ |
| Dash (stats) | 620 / 0,20 / 0,1 / g=0 | **=** | = mesmo `Player._get_dash_stats()` |
| Dash input | Duplo toque frente/trás | **=** (mesmo em `Player`) | = |
| Escudo | Não | **Sim**, 4 cargas, CD **4,25** s | ≠ |
| Pulo / corrida / HP / hitbox | baseline | baseline + escudo; números de dash diferentes | = hitbox/HP/pulo/wall jump; ≠ dash stats e escudo |

**Ficha:** [personagens/pistoleiro.md](personagens/pistoleiro.md)

---

## Arqueiro vs. Esqueleto

| Tópico | Esqueleto | Arqueiro | Notas |
|--------|-----------|----------|--------|
| Projétil principal | `Arrow`, **g = 0** | `Arrow`, **g = 1200** | ≠ arco balístico |
| Ricochetes padrão | 0 | **0** | = |
| Velocidade min / max | 420 / 900 | 420 / 900 | = |
| Tempo de carga | 1,0 s | 1,0 s | = |
| Cooldown tiro | ≥ 1,0 s | **0,4** s (`shoot_cooldown`) | ≠ mais disparos por segundo |
| Recoil | 170 (e variantes skills) | **170** nos ramos atuais | = |
| Skills | Triplo + raio | Espinhos + split + volley | ≠ |
| Dash (stats) | baseline | **=** | = |
| Dash input | Duplo toque frente/trás | **=** | = |
| Escudo | Não | **Sim**, 3 cargas; refletir cura **+6** HP | ≠ |
| Pulo / corrida / hitbox | baseline | baseline + escudo | = hitbox/pulo/wall jump; ≠ escudo |

**Ficha:** [personagens/arqueiro.md](personagens/arqueiro.md)

---

## Mago vs. Esqueleto

| Tópico | Esqueleto | Mago | Notas |
|--------|-----------|------|--------|
| Projétil “principal” | `Arrow` balístico reta | **`HomingMissile`** (extende `Arrow`) | ≠ comportamento teleguiado |
| Velocidade min / max | 420 / 900 | **360 / 520** | ≠ projétil mais lento |
| Tempo de carga | 1,0 s | **0,85** s (`missile_charge_time`) | ≠ |
| Gravidade no voo | 0 | **0** (míssil) | = |
| Ricochetes | 0 | **0** | = |
| Cooldown tiro | ≥ 1,0 s | **0,4** s | ≠ |
| Recoil no disparo principal | 170 | **139,4** (×0,82) | ≠ menos empurrão |
| Skills | Triplo + raio | Gelo + levitação + orbe | ≠ |
| Dash (stats) | baseline | **=** | = |
| Dash input | Duplo toque frente/trás | **=** | = |
| Escudo | Não | Não | = |
| Pulo / corrida / hitbox | baseline | baseline | = hitbox/wall jump; skills ≠ |

**Ficha:** [personagens/mago.md](personagens/mago.md)

---

## Esqueleto vs. Esqueleto

Documento canónico: [esqueleto_personagem_base.md](esqueleto_personagem_base.md) · Índice curto: [personagens/esqueleto.md](personagens/esqueleto.md).

---

## Ongma Epilef vs. Esqueleto

| Tópico | Esqueleto | Ongma Epilef | Notas |
|--------|-----------|--------------|--------|
| Script | `EsqueletoPlayer` | `OngmaEpilefPlayer` **extends EsqueletoPlayer** | Mesmo kit até overrides |
| `CharacterKind` | **3** | **4** | Menu / `RunConfig` |
| Projétil / dash / skills | baseline | **=** por padrão | `Game` usa `is EsqueletoPlayer` para flecha recta e HUD do buff |

**Ficha:** [personagens/ongma_epilef.md](personagens/ongma_epilef.md)

---

## Manutenção

Ao alterar balanceamento no código, atualize em conjunto:

1. A ficha do personagem em `docs/personagens/<nome>.md`
2. As linhas relevantes deste comparativo
3. Se o Esqueleto mudar, [esqueleto_personagem_base.md](esqueleto_personagem_base.md) primeiro — os outros documentos assumem esse baseline.
