# Esqueleto — ficha do personagem

A referência numérica completa, política de baseline (“todo personagem novo parte do Esqueleto”) e secções detalhadas estão no documento canónico:

**→ [Esqueleto — personagem base (referência de design)](../esqueleto_personagem_base.md)**

Script: `characters/esqueleto_player.gd` (`EsqueletoPlayer`).

Este ficheiro existe para manter **um documento por personagem** na pasta `docs/personagens/` sem duplicar o conteúdo longo da referência base.

**Resumo rápido (código actual):** dash por **duplo toque** frente/trás (comum em `Player`, não Shift); `gravity_scale` **0** no dash; cooldown **0,1** s; pulo no dash e wall jump na **base** `Player` (`dash_jump_*` e `wall_jump_*`); sprint ao **manter só frente** (`sprint_forward_hold_seconds`).
