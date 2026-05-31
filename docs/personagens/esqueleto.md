# Esqueleto — ficha do personagem

A referência numérica completa, política de baseline (“todo personagem novo parte do Esqueleto”) e secções detalhadas estão no documento canónico:

**→ [Esqueleto — personagem base (referência de design)](../esqueleto_personagem_base.md)**

Script: `characters/esqueleto_player.gd` (`EsqueletoPlayer`). Herda **toda** a locomoção, dash, mira e combate comum de `characters/player.gd` (`Player`); o Esqueleto só define **tiro + skills** e alguns hooks listados abaixo.

Este ficheiro resume o **padrão de design** do Esqueleto e aponta para o baseline longo sem o repetir.

---

## Padrão de herança

| Camada | Ficheiro | Papel |
|--------|----------|--------|
| Locomoção, mira, dash, pulo, wall jump, sprint visual, arena | `Player` | Comum a **todos** os duelistas |
| Tiro carregado reta, feixe, buff de velocidade, timers Vs | `EsqueletoPlayer` | Baseline de “arqueiro com flecha reta” |
| Família Esqueleto | `OngmaEpilefPlayer` etc. | `extends EsqueletoPlayer` — mesmas regras de spawn `g = 0` em `Game` quando `owner_player is EsqueletoPlayer` |

---

## Features básicas (o que o jogador “sente”)

- **Movimento:** solo e ar com `move_speed`, gravidade e pulo duplo (`Player`).
- **Dash:** acção **`p*_dash`** (**Shift** teclado, **B** comando); direcção: movimento horizontal (A/D / stick) ou eixo X da mira se neutro. Números em `_get_dash_stats()` (620 px/s, 0,20 s, CD 0,1 s, `gravity_scale` 0). Os outros duelistas usam duplo toque frente/trás; o Esqueleto **não** inicia dash por duplo toque.
- **Anti-spam de dash:** `dash_min_gap_seconds` entre inícios de dash; no ar, por defeito **um** dash por “voo” até tocar **chão** ou **parede** (`limit_air_dash_to_one` + reset em parede).
- **Pulo no dash:** impulso composto `(v_dash + v_jump) * dash_jump_impulse_mul` (exports `dash_jump_*`).
- **Corrida:** a corrida por **só segurar frente** (`sprint_mechanic_enabled`) está **desligada** por defeito. A **corrida pós-dash** (`post_dash_sprint_*`) está ligada: após um dash **para a frente**, segurar frente na janela abre sprint com `sprint_speed_multiplier` > 1.
- **Indicador de corrida:** anel no chão (`sprint_indicator_*`) quando `_sprint_active`.
- **Duplo toque estrito:** input vertical / stick entre toques invalida o par (ver `sistemas_core_arena_e_movimento.md`).
- **Wall jump:** um por sequência aérea até ao solo (`Player`).
- **Mira:** teclado+mouse ou stick direito com deadzone/smoothing (`Player`).

---

## O que é específico do `EsqueletoPlayer`

- **Tiro principal:** carregar + soltar; flecha com **g = 0** no voo (como pistoleiro); cooldown mínimo **≥ 1,0** s após disparo (`MIN_SHOOT_COOLDOWN_S`).
- **Buff de velocidade no tiro carregado (G / Y):** activa um período em que o tiro carregado sai com velocidade maior; CD e duração em `esqueleto_skill_buff_velocidade_tiro_*`; HUD via `special_buff_changed`.
- **Feixe (F / X, segurar/soltar):** carrega com `*_grenade`, solta com `shots_requested`; parâmetros `esqueleto_skill_feixe_*`; `_is_grenade_charging_active()` reflecte o carregamento do feixe.
- **ULT Chuva de ossos (R / LB):** fase **SUPER** 2,2 s (câmera + zoom + destaque) → 3 s de ossos verticais na metade adversária com knockback; CD ~38 s.
- **Dash durante o feixe:** `_dash_blocked_by_grenade_skill()` devolve **false** — pode dar dash enquanto carrega o feixe (o bloqueio por granada na base não aplica aqui da mesma forma).
- **Respawn Vs:** `_extra_reset_for_vs_round()` zera feixe, buff e tempos de duplo toque na base (o dash do Esqueleto usa `p*_dash`).

Para números e tabelas completas, usar sempre **[../esqueleto_personagem_base.md](../esqueleto_personagem_base.md)** e **[../sistemas_core_arena_e_movimento.md](../sistemas_core_arena_e_movimento.md)**.
