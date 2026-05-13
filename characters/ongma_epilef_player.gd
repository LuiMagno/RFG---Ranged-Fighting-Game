extends EsqueletoPlayer
class_name OngmaEpilefPlayer

## Personagem de teste / laboratório: herda o kit do Esqueleto (tiro carregado, feixe, buff de velocidade no tiro, dash duplo, etc.).
## Dash, wall jump e pulo no dash estão na classe `Player`; aqui só deltas de laboratório se precisares.


func is_ongma_epilef() -> bool:
	return true
