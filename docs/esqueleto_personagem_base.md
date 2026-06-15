# Esqueleto — personagem base (referência de design)

**Documentos relacionados:** arena, movimento, dash e física comuns em [sistemas_core_arena_e_movimento.md](sistemas_core_arena_e_movimento.md) · fichas por personagem em [personagens/](personagens/) · comparativo **vs.** este baseline em [comparativo_personagens_vs_esqueleto.md](comparativo_personagens_vs_esqueleto.md).

Este documento consolida os valores do **Esqueleto** (`EsqueletoPlayer` / `characters/esqueleto_player.gd`) e tudo que ele **herda** de `Player` (`characters/player.gd`), além de regras de spawn em `Game` (`levels/duel/game.gd`). O esqueleto usa a mesma cena física/visual que os outros duelistas em `levels/duel/main.tscn` (o script é trocado em runtime via `RunConfig`).

## Política de design (baseline de personagens)

Os números e comportamentos do **Esqueleto** definem o **padrão de referência** do projeto para duelo: velocidades de tiro, recoil, dash (no Esqueleto: acção `*_dash` — **Shift** / **B**; noutros duelistas: duplo toque frente/trás em `Player`), movimento, pulo, regras de **dash no ar** e **anti-encadeamento**, **corrida pós-dash** (opcional), wall jump na base, dimensão do corpo e relação com o `Game` (spawn de projéteis, gravidade no voo, etc.). A **corrida por só manter “frente”** (`sprint_mechanic_enabled`) existe na base mas está **desligada** por defeito; o pacing actual privilegia dash + **sprint após dash para a frente**. Ao equilibrar ou criar conteúdo novo, compara-se primeiro com esta folha antes de afastar valores “sem motivo”.

**Regra de trabalho:** daqui em diante, **todo personagem novo parte conceitual e numericamente do Esqueleto** — ou seja, copia-se o perfil do esqueleto (ou o script `esqueleto_player.gd` como ponto de partida) e **só depois** se alteram stats, skills e exceções de spawn à medida que o design do arquétipo exige. Personagens já existentes (pistoleiro, arqueiro, mago) continuam válidos, mas **evoluções e novos lutadores** devem documentar explicitamente o que mudou em relação a este baseline, para manter coerência de pacing e leitura de jogo.

**Família Esqueleto no código:** qualquer nó com script que **é** `EsqueletoPlayer` (inclui **Ongma Epilef**, `extends EsqueletoPlayer`) entra nas mesmas regras de `Game` que o esqueleto para flecha reta e HUD do buff de velocidade — ver `owner_player is EsqueletoPlayer` em `levels/duel/game.gd`. Ficha do laboratório: [personagens/ongma_epilef.md](personagens/ongma_epilef.md).

**Build modular (Esqueleto):** nos menus Vs e Treino, ao escolher **Esqueleto** (não Ongma), abre-se o painel lateral `ui/components/esqueleto_build_side_panel.tscn`. Cada jogador tem a sua build em `RunConfig` (`p1_esqueleto_build` / `p2_esqueleto_build`). O catálogo `characters/esqueleto/esqueleto_build_catalog.gd` (`EsqueletoBuildCatalog`) é a fonte única para menus e runtime; `EsqueletoPlayer.apply_build_from_run_config()` é chamado em `Game._assign_player_script` só quando `kind == ESQUELETO`.

| Slot (`RunConfig`) | ID default | Input | Comportamento (fase 1) |
|--------------------|------------|-------|-------------------------|
| `skill_1` | `feixe` | F / X (`*_grenade`) | Feixe carregar + soltar |
| `skill_2` | `buff_velocidade_tiro` | G / Y (`*_special`) | Buff velocidade do tiro carregado |
| `basic_shot` | `tiro_carregado` | RB / mouse (`*_shoot`) | Tiro carregado baseline |
| `dash` | `dash_acao` | Shift / B (`*_dash`) | Dash por botão (`uses_dash_action_button`) |
| `ult` | `chuva_ossos` | R / LB (`*_ult`) | ULT Chuva de ossos |

**Registar nova skill:** adicionar ID + label em `EsqueletoBuildCatalog.get_slot_options(slot_key)` e implementar o handler correspondente em `EsqueletoPlayer` (dispatch por `match` em `_process_skill_1`, `_process_skill_2`, `_process_basic_shot`, `uses_dash_action_button`, `_tentar_ativar_ult`). IDs desconhecidos fazem fallback para o default do slot.

---

**Controles (duelo, após `_ensure_input_map` em `game.gd`):**

No Vs, **só um** jogador pode usar **teclado+mouse**; o outro usa **controle**. Quem estiver em teclado+mouse usa o mesmo layout **WASD + mouse** (ações `p1_*` ou `p2_*` conforme o lado, mas mesmas teclas físicas).

| Ação | Teclado+mouse (`p1_*` ou `p2_*`) | Controle (RB / X / Y etc. em `p1_*` ou `p2_*`) |
|------|-----------------------------------|-----------------------------------------------|
| Tiro principal (carregar + soltar) | Botão esquerdo do mouse (`*_shoot`) | **RB** |
| Skill **Feixe** (carregar + soltar) | **F** (`*_grenade`) | **X** |
| Skill **Buff de velocidade do tiro carregado** (duração + CD próprios) | **G** (`*_special`) | **Y** |
| **ULT Chuva de ossos** (3 s, metade inimiga, CD alto) | **R** (`*_ult`) | **LB** (`*_ult`; escudo inactivo no Esqueleto) |
| **Dash (Esqueleto / Ongma)** | **`p*_dash`**: **Shift** (teclado) — direcção: **A/D** ou frente se neutro; **duplo toque não inicia dash**. | **`p*_dash`**: **B** — mesma lógica (stick esq. / frente). |
| **Dash (outros duelistas)** | Duplo toque **D**→**D** / **A**→**A**; `*_dash` não inicia dash. | Duplo toque frente/trás no stick; regras de duplo toque estrito (`game.gd` + `Player`). |

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
| Poder / integridade no choque | **20** / **20** (inicial = dano) | `Arrow.clash_power`, `Arrow.clash_integrity` — só activo quando pelo menos um projétil é da família Esqueleto (`EsqueletoPlayer`); ver secção 4.2 |
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
| `recoil_special_big` | **480** | Export na base; o feixe **não** usa este valor (recoil próprio abaixo) |
| `recoil_y_factor` | **0,25** | Componente vertical do recoil no tiro normal (`_apply_recoil`) |
| `recoil_decay` | **2400** | Quão rápido o vetor extra de recoil decai |
| `knockback_carry_x_decay` | **3200** | Decaimento por frame de `_carry_knockback_x` (recuo horizontal que se soma ao movimento) |
| Skill **Feixe** | `forca` **~760** px/s, ângulo **5–16°** | Horizontal: `add_carry_knockback_x` · Vertical: `_apply_velocity_knockback_once` só em Y — o movimento da base não apaga o recuo para trás |

Implementação: `_apply_recoil(shot_velocity, strength)` em `player.gd` (tiro normal) · feixe: `add_carry_knockback_x` + `_apply_velocity_knockback_once` (ver linha acima).

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
| `_is_grenade_charging_active()` | `true` enquanto o feixe está a carregar (`_feixe_carregando`) — usado na base para UI/bloqueios que dependem de “skill de granada” a carregar. |
| `_dash_blocked_by_grenade_skill()` | **`false`** — o dash **não** é bloqueado pelo carregamento do feixe (diferente do default da base). |
| `uses_dash_action_button()` | **`true`** — o dash inicia com **`p*_dash`** (Shift / B), não com duplo toque; direcção: eixo de movimento ou, se neutro, frente do jogador (`Player._dash_dir_sign_from_dash_button`). |
| `_preview_gravity_for_shot()` | **`0.0`** — pré-visualização de trajetória recta. |

### 4.1 Buff de velocidade do tiro carregado (`*_special`: G / Y)

| Parâmetro | Valor |
|-----------|--------|
| Duração do buff | **4,0** s | `esqueleto_skill_buff_velocidade_tiro_duracao_s` |
| Recarga (antes de voltar a poder activar) | **10,0** s | `esqueleto_skill_buff_velocidade_tiro_recarga_s` |
| Multiplicador de velocidade no tiro carregado | **2,0** × | `esqueleto_skill_buff_velocidade_tiro_multiplicador` (aplica-se à velocidade já interpolada por carga) |
| HUD | `special_buff_changed(true, 1, tempo_restante)` enquanto activo; `false` ao expirar ou no reset Vs |

### 4.1.1 Auto mutilação (Skill 2 G/Y — buff com custo de HP)

| Parâmetro | Valor |
|-----------|--------|
| Custo | **10** HP (requer `hp > 10` para activar) | `esqueleto_skill_auto_mutilacao_custo_hp` |
| Duração | **4,0** s | `esqueleto_skill_auto_mutilacao_duracao_s` |
| Recarga | **10,0** s | `esqueleto_skill_auto_mutilacao_recarga_s` |
| Velocidade de ataque | **+50%** (`1,5×` projéteis + cooldown entre tiros) | `esqueleto_skill_auto_mutilacao_vel_ataque_mul` |
| Velocidade de movimento | **+25%** (`1,25×`) | `esqueleto_skill_auto_mutilacao_vel_movimento_mul` |
| Visual | Brilho vermelho no corpo | `_refresh_esqueleto_combat_modulate` |
| HUD | Igual buff Skill 2 | `special_buff_changed` |

### 4.2 Feixe (segurar `*_grenade` e soltar: F / X)

Na prática é um disparo único via `shots_requested` com flags de dano/tamanho/gravidade.

| Parâmetro | Valor |
|-----------|--------|
| Cooldown | **4,25** s | `esqueleto_skill_feixe_recarga_s` |
| Tempo máximo de carga | **0,65** s | `esqueleto_skill_feixe_tempo_max_carga_s` |
| Escala (tamanho) | `lerp(1.85, 3.45, t)` | `esqueleto_skill_feixe_escala_min` … `esqueleto_skill_feixe_escala_max` |
| Dano | **36** | `esqueleto_skill_feixe_dano` |
| Feedback numérico no hit | **36** em tier **heavy** | `Player.damage_received` → `DamageNumbersLayer` (flutuante ~0,75 s) |
| Poder no choque | **36** | `clash_power` no payload = `esqueleto_skill_feixe_dano` |
| Integridade no choque | **36** | `esqueleto_skill_feixe_clash_integridade` (tunável; 36 aguenta 1 tiro normal de 20) |
| Velocidade | `lerp(min_launch × 1.05, max_launch × 1.42, t)` | `esqueleto_skill_feixe_velocidade_mul_min` / `esqueleto_skill_feixe_velocidade_mul_max` → **441** … **1278** px/s nos extremos |
| Gravidade do projétil | **0** | payload em `_disparar_feixe` |
| Ricochetes | **0** | `bounces: 0` |
| Posição de spawn | `muzzle.global_position + dir × (22.0 × size)` | offset ao longo da mira |
| Recoil (jogador) | **~760** px/s (`esqueleto_skill_feixe_recoil_forca`) | Horizontal: `add_carry_knockback_x` · Vertical: `_apply_velocity_knockback_once` em Y |
| Ângulo acima da horizontal | **5–16°** | `esqueleto_skill_feixe_recoil_angulo_acima_horizontal_graus` |
| Decaimento do carry X (base) | **3200** | `Player.knockback_carry_x_decay` |
| Tiro normal durante carga do feixe | Ramo de carregar `*_shoot` **não** corre enquanto `_feixe_carregando` | `EsqueletoPlayer._process_combat` (prioridade ao feixe) |

**Choque flecha×flecha (Esqueleto / Ongma):** em `Arrow._resolve_arrow_clash` — cada projétil subtrai o `clash_power` adversário da `clash_integrity`; quem ficar ≤ 0 explode; sobrevivente mantém integridade e continua. Mesmo poder (ex. 20 vs 20, 36 vs 36) → explosão mútua. Feixe vs 1 tiro normal → feixe com **16** HP; 2.º normal destrói ambos. Duelistas **fora** da família Esqueleto mantêm cancelamento instantâneo mútuo entre si.

### 4.2.1 Vaso carnívoro (Skill 1 F/X — carregar + arco)

| Parâmetro | Valor |
|-----------|--------|
| Activar | Segurar `*_grenade` (F / X) e soltar | `_process_skill_1_vaso` |
| Cooldown | **8,0** s | `esqueleto_skill_vaso_recarga_s` |
| Carga máxima | **0,75** s | `esqueleto_skill_vaso_tempo_max_carga_s` |
| Velocidade do arco | **280** → **920** px/s | `esqueleto_skill_vaso_vel_*` |
| Gravidade | **1500** px/s² | `esqueleto_skill_vaso_gravity` |
| Ângulo do arco | `launch_angle` + **38°** | `esqueleto_skill_vaso_lob_angulo_graus` |
| Alcance | Carga máxima atinge a metade inimiga | preview com gravidade |
| Impacto | Toca **superfície** → planta carnívora | `EsqueletoCarnivorousPot` |
| Planta | **10** s, morde em **104** px; pescoço segue inimigos e avança na mordida | `EsqueletoCarnivorousPlant` |
| Mordida | **8** dano + **1** carga putrefação | `esqueleto_skill_vaso_planta_*` |
| Putrefação | Até **5** cargas; **2** dano/tick/carga / **0,6** s / **4** s | `add_esqueleto_putrefacao_charge` |

### 4.2.2 Torreta (Skill 1 F/X ou Skill 2 G/Y — conforme build)

| Parâmetro | Valor |
|-----------|--------|
| Activação | `*_grenade` (Skill 1) ou `*_special` (Skill 2) — toque único |
| Cooldown | **10,0** s (só ao colocar; transformação não gasta CD) | `esqueleto_skill_torreta_recarga_s` |
| Disparos | **5** | `esqueleto_skill_torreta_disparos` |
| Dano por tiro | **20** | `esqueleto_skill_torreta_dano_tiro` |
| Intervalo entre tiros | **2,5** s | `esqueleto_skill_torreta_intervalo_disparo_s` |
| Vida | **30** (≥30 dano acumulado destrói) | `esqueleto_skill_torreta_vida` |
| Offset de spawn | **24** px na direcção que o personagem enfrenta | `esqueleto_skill_torreta_offset_spawn_x` |
| Queda / terreno | `CharacterBody2D` com gravidade; assenta em chão (layer 1) e patamares (16/32) | `EsqueletoTurret.TERRAIN_COLLISION_MASK` |
| Fim de vida | Desaparece logo após o **5.º** disparo (ou ao levar ≥30 dano) | `_process_combat` / `take_damage` |
| Mira | 360° — posição **actual** do inimigo a cada disparo | `EsqueletoTurret` + `AutoAimFiveWayUtil` |
| Limite | 1 torreta activa por jogador (nova só após a anterior morrer) | `Game._active_turrets` |
| Projétil | `Arrow` via `Game.spawn_esqueleto_turret_shot`; flag `esqueleto_torreta_tiro`; escala = tiro carregado |
| Destruição | Projéteis **inimigos** (`Arrow.take_damage` na torreta); feixe (36) destrói num hit | `arrow.gd` + `EsqueletoTurret.take_damage` |
| Pausa SUPER | Torreta pausa com outros projéteis durante animação ULT | `Game._is_pausable_combat_projectile` |

#### Torreta Sentinela (torreta activa + skill + **cima**)

| Parâmetro | Valor |
|-----------|--------|
| Activação | Mesmo botão da torreta **com** `move_up` / **`hover_up` (W)** / stick para cima, enquanto a torreta estiver no chão | `turret_sentinel_requested` |
| Transformação | Pernas ósseas; anda pelo chão; persegue inimigo em alcance médio e mantém distância ideal | `EsqueletoTurret.transform_to_sentinel` |
| Vida | **20** (cap ao transformar; dano já recebido conta) | `esqueleto_skill_torreta_sentinela_vida` |
| Disparos | **10** (magazine novo) | `esqueleto_skill_torreta_sentinela_disparos` |
| Dano por tiro | **11** | `esqueleto_skill_torreta_sentinela_dano_tiro` |
| Intervalo entre tiros | **1,15** s | `esqueleto_skill_torreta_sentinela_intervalo_disparo_s` |
| Velocidade de marcha | **95** px/s | `esqueleto_skill_torreta_sentinela_walk_speed` |
| Alcance de seguimento | **380** px (horizontal; persegue até entrar no alcance) | `esqueleto_skill_torreta_sentinela_alcance_seguir` |
| Distância ideal | **185** px (aproxima/afasta com deadband) | `esqueleto_skill_torreta_sentinela_distancia_ideal` |
| Disparo | Igual torreta estacionária — **sem limite de alcance**; mira no centro da hitbox do inimigo | `EsqueletoTurret` |

#### Torreta Foguete — Kamikaze oscilante (torreta activa + skill + **baixo**)

| Parâmetro | Valor |
|-----------|--------|
| Activação | Mesmo botão da torreta **com** `move_down` / **`hover_down` (S)** / `down`, enquanto a torreta estiver no chão | `turret_rocket_requested` |
| Cooldown evolução | **4,0** s entre sentinela/foguete na mesma torreta | `esqueleto_skill_torreta_evolution_recarga_s` |
| Fase carga | **0,3** s — travada, pernas compactam, cano vira propulsor; **pode ser destruída** | `esqueleto_skill_torreta_foguete_carga_s` |
| Voo | Aceleração contínua até **920** px/s; tracking leve **95°/s**; **1** ricochete em parede | `esqueleto_skill_torreta_foguete_*` |
| Impacto | Explosão raio **150** px; **36** dano base; knockback **520/260** | idem |
| Transferência de tiros | Cada tiro restante → **+4** dano e **+10%** vel. máx. do foguete | `bonus_dano_por_tiro` / `bonus_vel_por_tiro` |
| Sobrecarga | Inimigo em movimento ≥ **220** px/s no impacto → explosão **+35%** raio e **+25%** dano | `sobrecarga_vel_inimigo` |
| Projéteis | Empurra flechas/granadas leves na explosão | `_push_nearby_projectiles` |

### 4.2.3 Zumbi (Skill 1 F/X ou Skill 2 G/Y — conforme build)

| Parâmetro | Valor |
|-----------|--------|
| Invocar | Toque único no botão do slot | `_invocar_zumbi` |
| Re-activar | Mesmo botão com zumbi vivo → **explode** (sem cooldown extra) | `zumbi_detonate_requested` |
| Cooldown (só invocar) | **12,0** s | `esqueleto_skill_zumbi_recarga_s` |
| Velocidade de caminhada | **160** px/s (~62% do move_speed base) | `esqueleto_skill_zumbi_walk_speed` |
| Perseguição | Posição **actual** do inimigo no chão (eixo X) | `EsqueletoZombie` + `AutoAimFiveWayUtil` |
| Agarrar | Raio **48** px + alinhamento vertical **±40** px | `esqueleto_skill_zumbi_grab_radius` |
| Slow no agarrar | **0,55×** move_speed | `Player.set_esqueleto_zombie_slow_mul` |
| Vida | **25** | `esqueleto_skill_zumbi_vida` |
| Explosão | Raio **160** · dano **22** · knockback leve | `esqueleto_skill_zumbi_explosion_*` |
| Queda / terreno | Igual torreta (`collision_mask` 49) | `EsqueletoZombie` |
| Limite | 1 zumbi activo por jogador (nova invocação substitui) | `Game._active_zombies` |

### 4.2.4 Mandíbula espectral (Skill 1 F/X ou Skill 2 G/Y — conforme build)

| Parâmetro | Valor |
|-----------|--------|
| Invocar | Toque único no botão do slot | `_invocar_mandibula` |
| Alvo | Inimigo válido (`AutoAimFiveWayUtil`); sem alvo → **não gasta cooldown** | pré-check em `EsqueletoPlayer` |
| Posição | Persegue o **centro** da hitbox do oponente (`40×90`) — fica em cima do corpo | `Player.get_body_collision_rect` |
| Emergência | Sobe de baixo + escala (**0,7** s) + som `shoot_magic` — janela para ler e fugir | `esqueleto_skill_mandibula_emergencia_s` |
| Perseguição | Segue o centro do alvo por **2,5** s a **200** px/s | `esqueleto_skill_mandibula_perseguicao_s` |
| Acerto | Hitbox `48×56` encosta no oponente (ou snap ≤**34** px do centro) | `EsqueletoSpectralJaw` |
| Dano da mordida | **22** + knockback **300** / **150** (X / Y) | `esqueleto_skill_mandibula_knockback_*` |
| Podridão (DOT) | **5** dano / **0,5** s · **3,0** s + **slow 10%** (`0,9×`) | `apply_esqueleto_podridao` + `podridao_slow_mul` |
| VFX podridão | Inimigo **brilha verde** + **pulso** a cada tick | `Player` / `EsqueletoPlayer._apply_esqueleto_sprite_modulate` |
| Cooldown | **10,0** s | `esqueleto_skill_mandibula_recarga_s` |
| Visual mordida | Surgimento → perseguição com boca aberta → mordida → some | `projectiles/esqueleto_spectral_jaw/` |
| Falha | Perseguição expira sem alcançar → some (som `dash` abafado) | `_miss_and_fade` |
| Slow | **10%** enquanto a podridão durar; combina com slow do zumbi (usa o mais forte) | `get_esqueleto_locomotion_slow_mul` |
| Reaplicar | Refresca duração da podridão (não stacka ticks paralelos) | `apply_esqueleto_podridao` |

### 4.3 ULT — Chuva de ossos (`*_ult`: R / LB)

| Parâmetro | Valor |
|-----------|--------|
| Recarga | **38,0** s | `esqueleto_skill_ult_chuva_ossos_recarga_s` |
| Fase **acionamento + animação** (câmera + destaque) | **2,2** s | `esqueleto_skill_ult_chuva_ossos_fase_armagem_animacao_s` |
| Zoom na animação | **1,42×** | `esqueleto_skill_ult_chuva_ossos_super_zoom` |
| Duração do **efeito** (chuva, após animação) | **3,0** s | `esqueleto_skill_ult_chuva_ossos_duracao_s` |
| Intervalo entre ossos | **0,14** s (~21 projéteis) | `esqueleto_skill_ult_chuva_ossos_intervalo_s` |
| Dano por osso | **10** | `esqueleto_skill_ult_chuva_ossos_dano` |
| Knockback por osso | **380** / **180** (X / Y) | `esqueleto_skill_ult_chuva_ossos_knockback_*` |
| Velocidade de queda | **720** px/s (vertical, `g = 0`) | `esqueleto_skill_ult_chuva_ossos_velocidade_queda` |
| Zona | Metade **inimiga** apenas | `Player.get_enemy_half_x_range()` + spawn em `Game._run_esqueleto_bone_rain` |
| Brilho corporal | `Color(1.35, 1.15, 0.55)` | `esqueleto_skill_ult_chuva_ossos_modulate` |
| Câmera (animação) | Foco + zoom + callout **SUPER!** + vignette | `CameraSystem.show_super_highlight` |
| Efeito (chuva) | Após animação; tremor leve; câmera já repôs enquadramento | `Game._run_esqueleto_bone_rain` |
| Ambos jogadores | Parados **só** em acionamento + animação; **livres** no efeito | `Game._begin_ult_armagem_animacao` / `enter_ult_efeito_phase` |
| Timer Vs + projéteis no ar | **Pausados** durante acionamento + animação SUPER | `Game._set_combat_projectiles_paused` + skip `_vs_round_time_left` em `_process` |
| HUD | **SUPER!** → chuva (Xs) | `ult_status_changed(..., super_phase)` |
| Bloqueios | Não activa durante feixe a carregar, tiro a carregar ou ULT já activa | `_tentar_ativar_ult_chuva_ossos` |

---

## 5. Dash

**Activação no Esqueleto / Ongma:** `uses_dash_action_button()` → `p*_dash` just pressed (`Player._update_double_tap_forward_movement`). **Números do dash** (`_get_dash_stats()` na base), **pulo durante o dash** e **wall jump** estão em `Player` (iguais aos outros duelistas).

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
- **Tiro carregado do Esqueleto:** `_shoot_charge_blocks_dash()` devolve **false** — dash permitido enquanto `_is_charging` (barra de carga / trajetória mantêm-se até soltar ou cancelar).

**Pulo durante o dash:** `Player._apply_jump_during_dash()` — **`velocity = (v_dash + v_jump) × dash_jump_impulse_mul`**, com `v_dash` / `v_jump` definidos pelos exports `dash_jump_vertical_mul`, `dash_jump_horizontal_scale`, `dash_jump_impulse_mul` (arco diagonal forte vs. pulo normal).

**Invulnerabilidade no dash (só Esqueleto / Ongma):** export `esqueleto_dash_invuln_seconds` (**0,12** s por defeito) em `EsqueletoPlayer`. Ao iniciar o dash, `_esqueleto_dash_invuln_left` bloqueia **`take_damage`** e **`apply_knockback`**; projéteis em colisão directa (**flecha**, **fireball**, **espinho**, **orbe de gravidade**, etc.) **atravessam** o corpo (`Player.should_pass_through_projectile` + excepção de colisão). O timer corre independentemente de `_dash_time_left`. **`apply_pit_fall_penalty`** e dano em área (ex.: explosão de granada) **não** usam pass-through. Outros duelistas **não** têm esta invuln.

**Dash aéreo diagonal (só Esqueleto / Ongma):** hooks `_air_dash_hold_down_enabled()` e `_get_air_dash_diagonal_velocity()` em `EsqueletoPlayer`. Segurar **`p*_down`** enquanto `_dash_time_left > 0` e no ar aplica `velocity = speed × (cos θ, sin θ)` com `speed` de `_get_dash_stats()` e `θ = esqueleto_air_dash_down_angle_deg` (**35°** por defeito). A magnitude total mantém-se **620** px/s; soltar ↓ volta ao dash horizontal (`vy ≤ 0`). Conta como o **mesmo** dash aéreo (`limit_air_dash_to_one` inalterado).

**Queda rápida no ar (só Esqueleto / Ongma):** hooks `_air_fast_fall_enabled()` e `_get_air_fast_fall_gravity_mul()`. Segurar **`p*_down`** no ar **sem** dash activo aplica `gravity_accel × esqueleto_fast_fall_gravity_mul` (**2,5×** por defeito). **Exclusão mútua:** com dash activo, só diagonal — queda rápida não corre. No chão, `p*_down` em plataforma continua a ser drop-through (`Player._tick_platform_drop_through`).

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

- **Dash (Esqueleto / Ongma):** acção **`p*_dash`** (Shift / B), com direcção derivada do movimento horizontal (`uses_dash_action_button()` em `EsqueletoPlayer`).
- **Dash (outros duelistas):** duplo toque frente ou trás dentro de `sprint_double_tap_window` (`Player._update_double_tap_forward_movement`); duplo toque **estrito** (invalidação por input vertical / stick — ver [sistemas_core_arena_e_movimento.md](sistemas_core_arena_e_movimento.md)).
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

No **respawn Vs**, `EsqueletoPlayer._extra_reset_for_vs_round()` repõe `_last_forward_tap_time_s` e `_last_back_tap_time_s` (relevantes sobretudo se no futuro voltar a haver duplo toque noutros fluxos; o dash do Esqueleto usa `p*_dash`).

---

## 8. Blueprint / valores úteis para outros personagens

Além dos blocos acima, estes exports de `Player` costumam ser o “contrato” comum da arena:

| Parâmetro | Valor | Uso típico |
|-----------|--------|------------|
| `max_hp` | **100** | Vida |
| `hit_stun_time` | **0,14** s | Stun após knockback |
| `knockback_friction` | **2400** | Deslize horizontal ao perder controle |
| `special_cooldown` | **3,0** s | Cooldown genérico na base (o esqueleto usa timers próprios para feixe e buff) |
| `projectile_gravity_accel` | **1200** | Usado na prévia e por outros personagens; esqueleto zera a prévia e o spawn |
| `arena_padding_x` | **36** | Limite horizontal da metade da arena |

Camadas (duelo): jogadores `collision_mask = 3`; flechas em `arrow.tscn` com `collision_layer = 2` e `collision_mask = 11` (inclui layer de jogadores).

---

## 9. Referência rápida de arquivos

- `characters/esqueleto_player.gd` — feixe, buff de velocidade no tiro carregado, torreta, zumbi, cooldown mínimo de tiro, reset de toques no Vs.
- `projectiles/esqueleto_turret/esqueleto_turret.gd` + `.tscn` — entidade da torreta (mira, disparos, HP).
- `projectiles/esqueleto_zombie/esqueleto_zombie.gd` + `.tscn` — zumbi (perseguição, agarrar, explosão).
- `characters/ongma_epilef_player.gd` — laboratório; `extends EsqueletoPlayer`.
- `characters/player.gd` — movimento, mira, recoil, pulo, dash (`uses_dash_action_button` / duplo toque, gap mínimo, dash no ar com reset em chão/parede), `_get_dash_stats()`, wall jump, `start_dash_with_direction`, pulo no dash (vector composto), corrida clássica opcional, **corrida pós-dash**, indicador visual de sprint, gravidade/clamp no dash, duplo toque estrito (teclado + `move_up`/`move_down` no comando).
- `levels/duel/game.gd` — flecha com `g = 0` se pistoleiro **ou** `owner_player is EsqueletoPlayer`; HUD do buff para `left_player/right_player is EsqueletoPlayer`; spawn de `Arrow`.
- `projectiles/arrow/arrow.gd` + `arrow.tscn` — física/dano/tamanho base do projétil.
- `levels/duel/main.tscn` — dimensões do corpo, colisor, muzzle, UI de carga/trajetória.

Se alterar um valor de balanceamento, prefira manter **exports** no script ou propriedades na cena e atualizar este documento na mesma alteração para o esqueleto continuar servindo de referência única.
