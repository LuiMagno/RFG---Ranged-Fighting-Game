extends EsqueletoPlayer
class_name OngmaEpilefPlayer

## Personagem de teste / laboratório: herda todo o kit do Esqueleto (tiro carregado, triplo, raio, dash duplo, etc.).
## Dash, wall jump e pulo no dash estão na classe `Player`; aqui só deltas de laboratório se precisares.


func is_ongma_epilef() -> bool:
	return true
