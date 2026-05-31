# Ongma Epilef — ficha (personagem de teste)

- **Script:** [`characters/ongma_epilef_player.gd`](../../characters/ongma_epilef_player.gd) (`OngmaEpilefPlayer`).
- **Herdança:** `extends EsqueletoPlayer` — mesmo kit que o [Esqueleto (baseline)](../esqueleto_personagem_base.md) (tiro carregado, feixe F/X, buff G/Y, **ULT chuva de ossos R/LB**, dash Shift/B, etc.). Dash, wall jump e sprint estão em [`Player`](../../characters/player.gd) para todos os duelistas.
- **Enum:** `Player.CharacterKind.ONGMA_EPILEF` (valor **4**).

## Regra de trabalho

O que for **comum a todos os duelistas** deve viver em [`characters/player.gd`](../../characters/player.gd). O que for **só do arquétipo esqueleto** fica em [`characters/esqueleto_player.gd`](../../characters/esqueleto_player.gd). Aqui (`ongma_epilef_player.gd`) entram apenas **deltas de laboratório**; se algo passar a servir vários personagens, subir para `Player` (hooks) ou para uma classe intermédia futura.

## Documentação relacionada

- Baseline numérico e política de personagens: [esqueleto_personagem_base.md](../esqueleto_personagem_base.md)
- Sistemas de arena e movimento: [sistemas_core_arena_e_movimento.md](../sistemas_core_arena_e_movimento.md)
