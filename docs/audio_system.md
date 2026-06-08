# Sistema de áudio (SFX)

Este documento descreve o sistema de efeitos sonoros do duelo 2D: arquitetura, sons disponíveis, pontos de integração no código e como substituir ou adicionar novos sons.

**Implementação principal:** `core/sfx_manager.gd` (autoload `SfxManager` em `project.godot`).

---

## 1. Visão geral

No arranque, o `SfxManager` gera sons **procedurais** (ondas senoidais, ruído e “whooshes”) e guarda-os em memória como `AudioStreamWAV`.

Quando existir um ficheiro real em `res://audio/sfx/<id>.ogg` (ou `.wav` / `.mp3`), esse ficheiro **tem prioridade** sobre o placeholder procedural.

```
SfxManager.play("shoot_bow", posição)
    → cache em memória?
    → ficheiro em audio/sfx/shoot_bow.ogg?
    → ficheiro .wav / .mp3?
    → som procedural pré-gerado
    → AudioStreamPlayer2D (com posição) ou AudioStreamPlayer (global)
```

### Ficheiros e pastas

| Caminho | Função |
|---------|--------|
| `core/sfx_manager.gd` | Motor de áudio (autoload) |
| `audio/sfx/` | Pasta para ficheiros `.ogg` / `.wav` / `.mp3` futuros |
| `project.godot` | Registo `SfxManager="*res://core/sfx_manager.gd"` |

### Buses de áudio

Criados automaticamente em `_ensure_audio_buses()`:

| Bus | Uso |
|-----|-----|
| `Master` | Saída final (padrão Godot) |
| `SFX` | Efeitos posicionais na arena (`AudioStreamPlayer2D`) |
| `UI` | Sons globais sem posição (`AudioStreamPlayer`) |

### Pools

- **14** `AudioStreamPlayer2D` — sons com posição no mundo (tiros, impactos, explosões).
- **4** `AudioStreamPlayer` — sons globais (sem `world_pos`).

Se todos os players estiverem ocupados, o mais antigo é reutilizado.

---

## 2. API pública

### `SfxManager.play(sfx_id, world_pos, pitch_scale, volume_db)`

| Parâmetro | Default | Descrição |
|-----------|---------|-----------|
| `sfx_id` | — | ID do som (`"shoot_bow"`, `"hit_light"`, etc.) |
| `world_pos` | `NO_POSITION` | Posição 2D na arena; sem posição = som global (bus UI) |
| `pitch_scale` | aleatório 0,94–1,06 | Tom; valor fixo > 0 desativa a variação |
| `volume_db` | `0.0` | Volume em decibéis (negativo = mais baixo) |

### `SfxManager.play_shot(owner_player, spawn_position, shot_flags, is_homing)`

Escolhe o som de disparo conforme personagem e flags:

| Condição | Som |
|----------|-----|
| `esqueleto_feixe` ou `archer_split_child` | *(silêncio — tratado noutro sítio)* |
| `spike_shot` / `spike_volley` | `shoot_spike` |
| Míssil teleguiado (`is_homing`) | `shoot_magic` |
| Pistoleiro ou Esqueleto | `shoot_gun` |
| Resto | `shoot_bow` |

### `SfxManager.play_arrow_hit(hit_position, damage, flags)`

| Condição | Som |
|----------|-----|
| `esqueleto_feixe` | `hit_feixe` |
| `damage >= 28` ou `esqueleto_chuva_osso` | `hit_heavy` |
| Resto | `hit_light` |

---

## 3. Sons disponíveis

Todos os IDs abaixo têm placeholder procedural em `_build_procedural_library()` e podem ser substituídos por ficheiros em `audio/sfx/<id>.ogg` (ou `.wav` / `.mp3`).

### Lista completa (21 IDs)

```
shoot_bow
shoot_gun
shoot_spike
shoot_magic
shoot_feixe
shoot_ice
shoot_orb
hit_light
hit_heavy
hit_feixe
explosion
explosion_small
ricochet
dash
jump
shield_block
freeze
pit_fall
grenade_throw
grenade_bounce
ult_start
```

| # | ID | Categoria |
|---|-----|-----------|
| 1 | `shoot_bow` | Disparo |
| 2 | `shoot_gun` | Disparo |
| 3 | `shoot_spike` | Disparo |
| 4 | `shoot_magic` | Disparo |
| 5 | `shoot_feixe` | Disparo |
| 6 | `shoot_ice` | Disparo |
| 7 | `shoot_orb` | Disparo |
| 8 | `hit_light` | Impacto |
| 9 | `hit_heavy` | Impacto |
| 10 | `hit_feixe` | Impacto |
| 11 | `explosion` | Explosão |
| 12 | `explosion_small` | Explosão |
| 13 | `ricochet` | Explosão / ricochete |
| 14 | `dash` | Movimento |
| 15 | `jump` | Movimento |
| 16 | `shield_block` | Movimento / defesa |
| 17 | `freeze` | Status |
| 18 | `pit_fall` | Ambiente |
| 19 | `grenade_throw` | Granada |
| 20 | `grenade_bounce` | Granada |
| 21 | `ult_start` | Habilidade especial |

### Detalhe por categoria

#### Disparos e habilidades

| ID | Tipo procedural | Onde toca |
|----|-----------------|-----------|
| `shoot_bow` | whoosh agudo→grave | Flecha / split do arqueiro |
| `shoot_gun` | ruído curto | Pistoleiro, Esqueleto (tiros normais) |
| `shoot_spike` | whoosh | Espinhos do arqueiro |
| `shoot_magic` | tom | Míssil teleguiado do mago |
| `shoot_feixe` | tom grave | Feixe do Esqueleto |
| `shoot_ice` | tom agudo | Lançamento de míssil de gelo |
| `shoot_orb` | tom grave | Orbe gravitacional |
| `ult_start` | tom longo grave | ULT chuva de ossos (Esqueleto) |

#### Impactos e explosões

| ID | Tipo procedural | Onde toca |
|----|-----------------|-----------|
| `hit_light` | impacto | Flecha acerta jogador (dano leve) |
| `hit_heavy` | impacto forte | Dano alto, chuva de ossos, granada |
| `hit_feixe` | impacto | Feixe do Esqueleto acerta |
| `explosion` | ruído longo | Granada detona |
| `explosion_small` | ruído curto | Colisão flecha×flecha |
| `ricochet` | tom agudo | Flecha ricocheteia |

#### Movimento e ambiente

| ID | Tipo procedural | Onde toca |
|----|-----------------|-----------|
| `dash` | whoosh | Dash do jogador |
| `jump` | tom curto | Pulo (volume −6 dB) |
| `shield_block` | tom | Escudo bloqueia flecha |
| `freeze` | tom agudo | Congelamento / detonação de gelo |
| `pit_fall` | whoosh | Queda no abismo |
| `grenade_throw` | whoosh | Lançamento de granada |
| `grenade_bounce` | impacto | Granada ricocheteia no chão |

---

## 4. Pontos de integração (só linhas de áudio)

Nenhuma mecânica de jogo foi alterada — apenas chamadas `SfxManager.*` nos momentos certos.

### `levels/duel/game.gd`

| Evento | Chamada |
|--------|---------|
| Spawn de flecha/projétil | `SfxManager.play_shot(...)` |
| Granada lançada | `SfxManager.play("grenade_throw", ...)` |
| Míssil de gelo | `SfxManager.play("shoot_ice", ...)` |
| Orbe gravitacional | `SfxManager.play("shoot_orb", ...)` |
| Feixe do Esqueleto | `SfxManager.play("shoot_feixe", ...)` |
| Leque de espinhos | `SfxManager.play("shoot_spike", ...)` |
| Split do arqueiro (5 flechas) | `SfxManager.play("shoot_bow", ...)` uma vez |
| Acerto de flecha em jogador | `SfxManager.play_arrow_hit(...)` |
| ULT chuva de ossos | `SfxManager.play("ult_start", ...)` |

### `characters/player.gd`

| Evento | Chamada |
|--------|---------|
| Dash | `SfxManager.play("dash", ...)` |
| Pulo | `SfxManager.play("jump", ..., 1.0, -6.0)` |
| Escudo bloqueia | `SfxManager.play("shield_block", ...)` |
| Congelamento (`freeze_for`) | `SfxManager.play("freeze", ...)` |
| Queda no pit | `SfxManager.play("pit_fall", ...)` |

### Projéteis

| Ficheiro | Evento | Chamada |
|----------|--------|---------|
| `projectiles/arrow/arrow.gd` | Ricochete | `SfxManager.play("ricochet", ...)` |
| `projectiles/arrow/arrow.gd` | Colisão flecha×flecha | `SfxManager.play("explosion_small", ...)` |
| `projectiles/grenade/grenade.gd` | Ricochete | `SfxManager.play("grenade_bounce", ...)` |
| `projectiles/grenade/grenade.gd` | Explosão | `SfxManager.play("explosion", ...)` |
| `projectiles/grenade/grenade.gd` | Dano em área | `SfxManager.play("hit_heavy", ...)` |
| `projectiles/ice_missile/ice_missile.gd` | Detonação | `SfxManager.play("freeze", ...)` |

---

## 5. Sons procedurais — como são gerados

No `_ready()`, `_build_procedural_library()` preenche o dicionário `_procedural`. Cada som é uma sequência de amostras a **22050 Hz**, convertida para WAV 16-bit em `_wav_from_samples()`.

### Receitas

| Função | Descrição |
|--------|-----------|
| `_make_tone` | Onda `sin()` com envelope de attack/fade |
| `_make_whoosh` | Frequência que desce + ruído (movimento rápido) |
| `_make_noise_burst` | Ruído aleatório com decay; filtro passa-baixo opcional |
| `_make_impact` | Tom descendente + ruído (pancadas) |

### Prioridade de ficheiros

Ordem em `_resolve_stream()`:

1. `.ogg`
2. `.wav`
3. `.mp3`
4. Procedural

Recomendação para assets finais: **`.ogg`** em `audio/sfx/`.

---

## 6. Como adicionar um som novo

### Com ficheiro de áudio

1. Escolher ID em `snake_case` (ex.: `round_win`).
2. Colocar `audio/sfx/round_win.ogg`.
3. Chamar no evento: `SfxManager.play("round_win")` (global) ou `SfxManager.play("round_win", posição)`.

Não é obrigatório alterar `sfx_manager.gd` se o ficheiro existir.

### Só procedural (placeholder)

1. Em `_build_procedural_library()`, acrescentar linha, ex.:
   ```gdscript
   _procedural["round_win"] = _make_tone(680.0, 0.14, 0.01, true, 0.36)
   ```
2. Ligar `SfxManager.play("round_win")` no sítio certo do código.

---

## 7. Compatibilidade (Godot 4.0.3+)

O código evita APIs que falham em versões antigas do Godot 4:

- `pow()` em vez de `powf()`
- `Vector2(INF, INF)` em vez de `Vector2.INF`
- Tipos explícitos (`var path: String`) onde a inferência falha
- Sem `PackedStringArray()` em constantes
- Sem `panning_strength` em `AudioStreamPlayer2D`

---

## 8. O que **não** está no sistema

- **Música de fundo** (menu / combate)
- **Sons de UI** nos menus (`ui_confirm`, etc. — não ligados)
- **Vitória de round / partida** (`round_win`, `match_victory`)
- **Voz / diálogo**

Estes podem ser adicionados seguindo a secção 6.

---

