extends Player
class_name EsqueletoPlayer

## Baseline de duelo: tiro carregado (velocidade proporcional à carga), flecha sem gravidade no voo.
## Três skills + ULT do Esqueleto (mapeamento em `game.gd` / `project.godot`):
## - **Skill Esqueleto — Feixe:** ação `p*_grenade` (teclado **F**, controle **X**) — segura e solta para disparar o projétil grande.
## - **Skill Esqueleto — Buff de velocidade:** ação `p*_special` (teclado **G**, controle **Y**) — tiro carregado (RB / mouse) e **feixe** saem mais rápidos enquanto o buff durar.
## - **Skill Esqueleto — ULT Chuva de ossos** (`p*_ult`: **R** / **LB**), em três fases:
##   1. **Acionamento** — tecla solta, inicia a ULT (ambos parados).
##   2. **Animação** — SUPER + câmera (~`esqueleto_skill_ult_chuva_ossos_fase_armagem_animacao_s`; ambos parados).
##   3. **Efeito** — chuva de ossos na metade inimiga (~`esqueleto_skill_ult_chuva_ossos_duracao_s`; ambos com movimento e skills livres).
## Tiro base: mínimo 1 s entre disparos após soltar o carregamento (`MIN_SHOOT_COOLDOWN_S`).
## Velocidade de **viagem** dos projéteis (px/s). Treino: `RunConfig`; Vs: export abaixo. Tiro carregado, feixe e queda da ULT.
@export_range(1.0, 2.0, 0.01) var esqueleto_velocidade_projeteis_mul: float = 1.5
## Fração do bónus de velocidade aplicada à queda da ULT (0.5 → global 1.5× ⇒ chuva 1.25×).
@export_range(0.0, 1.0, 0.05) var esqueleto_chuva_ossos_velocidade_viagem_peso: float = 0.5
## Escala visual do feixe (tiro carregado e chuva ULT usam `esqueleto_tiro_carregado_chuva_tamanho_mul`).
@export_range(0.5, 3.0, 0.05) var esqueleto_projetil_tamanho_mul: float = 1.2
## Tiro carregado e ossos da ULT (+20% extra sobre o ajuste global anterior → 1,44× vs. original).
@export_range(0.5, 3.0, 0.05) var esqueleto_tiro_carregado_chuva_tamanho_mul: float = 1.44

const MIN_SHOOT_COOLDOWN_S := 1.0
const ESQUELETO_SPRITE_FRAMES_PATH := "res://art/skeleton/esqueleto_sprite_frames.tres"
## Alinha os pés ao retângulo de colisão (~40×90); sprite base 32×32.
const BODY_SPRITE_OFFSET := Vector2(0, 12)
const BODY_SPRITE_SCALE := Vector2(2.8, 2.8)
const BODY_MOVE_SPEED_THRESHOLD := 18.0
## Parado / ULT parado; no ar usa `BODY_JUMP_ANIM`.
const BODY_IDLE_ANIM := "idle_smoking"
const BODY_DASH_ANIM := "dash"
const BODY_JUMP_ANIM := "jump"

## Skill Esqueleto — Feixe (`*_grenade`)
@export var esqueleto_skill_feixe_recarga_s: float = 4.25
@export var esqueleto_skill_feixe_tempo_max_carga_s: float = 0.65
@export var esqueleto_skill_feixe_escala_min: float = 1.85
@export var esqueleto_skill_feixe_escala_max: float = 3.45
@export var esqueleto_skill_feixe_dano: int = 36
## Integridade do feixe no choque flecha×flecha (por defeito = dano; 36 aguenta 1 tiro normal de 20).
@export var esqueleto_skill_feixe_clash_integridade: int = 36
@export var esqueleto_skill_feixe_velocidade_mul_min: float = 1.05
@export var esqueleto_skill_feixe_velocidade_mul_max: float = 1.42
## Recoil do feixe: horizontal em `add_carry_knockback_x` (sobrevive ao `velocity.x = dir*speed` no próximo frame); vertical **uma vez** em `velocity` — arco baixo pela gravidade.
@export_range(5.0, 16.0, 0.5) var esqueleto_skill_feixe_recoil_angulo_acima_horizontal_graus: float = 10.0
@export_range(500.0, 1200.0, 10.0) var esqueleto_skill_feixe_recoil_forca: float = 2000.0

## Skill Esqueleto — Vaso carnívoro (Skill 1 F/X; arco carregado → planta no chão)
@export var esqueleto_skill_vaso_recarga_s: float = 8.0
@export var esqueleto_skill_vaso_tempo_max_carga_s: float = 0.75
@export var esqueleto_skill_vaso_vel_min: float = 280.0
@export var esqueleto_skill_vaso_vel_max: float = 920.0
@export var esqueleto_skill_vaso_gravity: float = 1500.0
@export_range(10.0, 60.0, 1.0) var esqueleto_skill_vaso_lob_angulo_graus: float = 38.0
@export var esqueleto_skill_vaso_planta_duracao_s: float = 10.0
@export var esqueleto_skill_vaso_planta_raio_mordida: float = 104.0
@export var esqueleto_skill_vaso_planta_dano_mordida: int = 8
@export var esqueleto_skill_vaso_planta_intervalo_mordida_s: float = 0.55
@export var esqueleto_skill_vaso_putrefacao_cargas: int = 1
@export var esqueleto_skill_vaso_putrefacao_duracao_s: float = 4.0
@export var esqueleto_skill_vaso_putrefacao_dano_por_carga: int = 2
@export var esqueleto_skill_vaso_putrefacao_intervalo_tick_s: float = 0.6

## Skill Esqueleto — Torreta (Skill 1 F/X ou Skill 2 G/Y, conforme build)
@export var esqueleto_skill_torreta_recarga_s: float = 10.0
@export var esqueleto_skill_torreta_disparos: int = 5
@export var esqueleto_skill_torreta_dano_tiro: int = 20
@export var esqueleto_skill_torreta_intervalo_disparo_s: float = 2.5
@export var esqueleto_skill_torreta_vida: int = 30
@export var esqueleto_skill_torreta_offset_spawn_x: float = 24.0
@export var esqueleto_skill_torreta_sentinela_vida: int = 20
@export var esqueleto_skill_torreta_sentinela_disparos: int = 10
@export var esqueleto_skill_torreta_sentinela_dano_tiro: int = 11
@export var esqueleto_skill_torreta_sentinela_intervalo_disparo_s: float = 1.15
@export var esqueleto_skill_torreta_sentinela_walk_speed: float = 95.0
@export var esqueleto_skill_torreta_sentinela_alcance_seguir: float = 380.0
@export var esqueleto_skill_torreta_sentinela_distancia_ideal: float = 185.0
@export var esqueleto_skill_torreta_evolution_recarga_s: float = 4.0
@export var esqueleto_skill_torreta_foguete_carga_s: float = 0.3
@export var esqueleto_skill_torreta_foguete_dano_base: int = 36
@export var esqueleto_skill_torreta_foguete_raio: float = 150.0
@export var esqueleto_skill_torreta_foguete_knockback_x: float = 520.0
@export var esqueleto_skill_torreta_foguete_knockback_up: float = 260.0
@export var esqueleto_skill_torreta_foguete_aceleracao: float = 1850.0
@export var esqueleto_skill_torreta_foguete_vel_max: float = 920.0
@export var esqueleto_skill_torreta_foguete_tracking_graus_s: float = 95.0
@export var esqueleto_skill_torreta_foguete_ricochetes: int = 1
@export var esqueleto_skill_torreta_foguete_bonus_dano_por_tiro: int = 4
@export_range(0.05, 0.35, 0.01) var esqueleto_skill_torreta_foguete_bonus_vel_por_tiro: float = 0.1
@export var esqueleto_skill_torreta_foguete_sobrecarga_vel_inimigo: float = 220.0

## Skill Esqueleto — Zumbi (Skill 1 F/X ou Skill 2 G/Y; re-activar explode)
@export var esqueleto_skill_zumbi_recarga_s: float = 12.0
@export var esqueleto_skill_zumbi_walk_speed: float = 160.0
@export var esqueleto_skill_zumbi_grab_radius: float = 48.0
@export_range(0.15, 1.0, 0.05) var esqueleto_skill_zumbi_slow_mul: float = 0.55
@export var esqueleto_skill_zumbi_vida: int = 25
@export var esqueleto_skill_zumbi_explosion_radius: float = 160.0
@export var esqueleto_skill_zumbi_explosion_dano: int = 22
@export var esqueleto_skill_zumbi_explosion_knockback_x: float = 420.0
@export var esqueleto_skill_zumbi_explosion_knockback_up: float = 180.0
@export var esqueleto_skill_zumbi_offset_spawn_x: float = 24.0

## Skill Esqueleto — Mandíbula espectral (Skill 1 F/X ou Skill 2 G/Y; alvo inimigo + podridão)
@export var esqueleto_skill_mandibula_recarga_s: float = 10.0
@export var esqueleto_skill_mandibula_dano_mordida: int = 22
@export var esqueleto_skill_mandibula_podridao_dano_tick: int = 5
@export var esqueleto_skill_mandibula_podridao_duracao_s: float = 3.0
@export var esqueleto_skill_mandibula_podridao_intervalo_tick_s: float = 0.5
@export var esqueleto_skill_mandibula_emergencia_s: float = 0.7
@export var esqueleto_skill_mandibula_perseguicao_s: float = 2.5
@export var esqueleto_skill_mandibula_velocidade_perseguicao: float = 200.0
@export var esqueleto_skill_mandibula_knockback_x: float = 300.0
@export var esqueleto_skill_mandibula_knockback_up: float = 150.0
@export_range(0.15, 1.0, 0.01) var esqueleto_skill_mandibula_podridao_slow_mul: float = 0.9

## Skill Esqueleto — Buff de velocidade (`*_special`; tiro carregado + feixe)
@export var esqueleto_skill_buff_velocidade_tiro_duracao_s: float = 4.0
@export var esqueleto_skill_buff_velocidade_tiro_recarga_s: float = 10.0
@export var esqueleto_skill_buff_velocidade_tiro_multiplicador: float = 2.0

## Skill Esqueleto — Auto mutilação (Skill 2 G/Y; buff com custo de HP)
@export var esqueleto_skill_auto_mutilacao_custo_hp: int = 10
@export var esqueleto_skill_auto_mutilacao_duracao_s: float = 4.0
@export var esqueleto_skill_auto_mutilacao_recarga_s: float = 10.0
@export_range(1.0, 2.5, 0.05) var esqueleto_skill_auto_mutilacao_vel_ataque_mul: float = 1.5
@export_range(1.0, 2.0, 0.05) var esqueleto_skill_auto_mutilacao_vel_movimento_mul: float = 1.25

## Skill Esqueleto — ULT Chuva de ossos (`*_ult`: teclado R, controle LB)
@export var esqueleto_skill_ult_chuva_ossos_recarga_s: float = 38.0
## Duração da fase **acionamento + animação** (SUPER/câmera); durante isto ninguém se move.
@export var esqueleto_skill_ult_chuva_ossos_fase_armagem_animacao_s: float = 2.2
## Frações do tempo SUPER (soma ≈ 1): aproximar → segurar foco → voltar à arena.
@export_range(0.1, 0.7, 0.01) var esqueleto_skill_ult_super_pan_fraction: float = 0.45
@export_range(0.1, 0.7, 0.01) var esqueleto_skill_ult_super_hold_fraction: float = 0.30
@export_range(0.1, 0.7, 0.01) var esqueleto_skill_ult_super_return_fraction: float = 0.25
@export var esqueleto_skill_ult_chuva_ossos_super_zoom: float = 1.42
@export var esqueleto_skill_ult_chuva_ossos_duracao_s: float = 3.0
@export var esqueleto_skill_ult_chuva_ossos_intervalo_s: float = 0.14
@export var esqueleto_skill_ult_chuva_ossos_dano: int = 10
@export var esqueleto_skill_ult_chuva_ossos_velocidade_queda: float = 720.0
@export var esqueleto_skill_ult_chuva_ossos_knockback_x: float = 380.0
@export var esqueleto_skill_ult_chuva_ossos_knockback_up: float = 180.0
@export var esqueleto_skill_ult_chuva_ossos_modulate: Color = Color(1.35, 1.15, 0.55)
## Tremor contínuo leve na fase efeito (Camera2D.offset ambiente; não usa shake_duracao_s).
@export var esqueleto_skill_ult_chuva_ossos_shake_intensidade: float = 3.0
@export var esqueleto_skill_ult_chuva_ossos_shake_duracao_s: float = 0.18
## Invulnerabilidade no dash (só Esqueleto / Ongma): bloqueia dano e knockback; timer independente da duração do dash.
@export_range(0.0, 0.5, 0.01) var esqueleto_dash_invuln_seconds: float = 0.12
## Dash no ar + segurar ↓: ângulo da diagonal (velocidade total = speed do dash).
@export_range(0.0, 89.0, 1.0) var esqueleto_air_dash_down_angle_deg: float = 35.0
## No ar sem dash: multiplicador de gravidade ao segurar ↓ (queda rápida).
@export_range(1.0, 6.0, 0.1) var esqueleto_fast_fall_gravity_mul: float = 2.5

var _esqueleto_buff_velocidade_tiro_ativo := false
var _esqueleto_buff_velocidade_tiro_tempo_restante_s := 0.0
var _esqueleto_buff_velocidade_tiro_cd_restante_s := 0.0
var _auto_mutilacao_ativo := false
var _auto_mutilacao_tempo_restante_s := 0.0
var _auto_mutilacao_cd_restante_s := 0.0
var _feixe_cd_restante_s := 0.0
var _feixe_carregando := false
var _feixe_tempo_carga_s := 0.0
var _vaso_cd_restante_s := 0.0
var _vaso_carregando := false
var _vaso_tempo_carga_s := 0.0
var _torreta_cd_restante_s := 0.0
var _torreta_active := false
var _torreta_evolution_cd_restante_s := 0.0
var _zumbi_cd_restante_s := 0.0
var _zumbi_active := false
var _mandibula_cd_restante_s := 0.0
var _esqueleto_ult_cd_restante_s := 0.0
var _esqueleto_chuva_ossos_ativa := false
var _esqueleto_ult_armagem_animacao_restante_s := 0.0
var _esqueleto_chuva_ossos_tempo_restante_s := 0.0

var _body_sprite: AnimatedSprite2D
var _orig_sprite_modulate: Color = Color.WHITE
## Bloqueia troca para idle/walk enquanto hurt/attack/death/dash/jump não terminam.
var _sprite_action_lock := ""
var _esqueleto_was_on_floor := true
var _esqueleto_dash_invuln_left := 0.0
var _build: Dictionary = EsqueletoBuildCatalog.get_default_build()


func is_esqueleto() -> bool:
	return true


func _ready() -> void:
	shoot_cooldown = maxf(MIN_SHOOT_COOLDOWN_S, shoot_cooldown)
	super._ready()
	apply_build_from_run_config()
	_setup_esqueleto_body_sprite()


func apply_build_from_run_config() -> void:
	_build = RunConfig.get_esqueleto_build(player_id)


func _build_skill(slot_key: StringName) -> StringName:
	var skill_id: StringName = _build.get(slot_key, EsqueletoBuildCatalog.get_default_skill_for_slot(slot_key))
	return EsqueletoBuildCatalog.resolve_skill_for_slot(slot_key, skill_id)


func get_projetil_velocidade_viagem_mul() -> float:
	if RunConfig.mode == RunConfig.Mode.TRAINING:
		return RunConfig.get_esqueleto_projetil_velocidade_mul()
	return esqueleto_velocidade_projeteis_mul


func get_chuva_ossos_velocidade_viagem_mul() -> float:
	var g := get_projetil_velocidade_viagem_mul()
	return 1.0 + (g - 1.0) * esqueleto_chuva_ossos_velocidade_viagem_peso


func get_chuva_ossos_velocidade_queda() -> float:
	return esqueleto_skill_ult_chuva_ossos_velocidade_queda * get_chuva_ossos_velocidade_viagem_mul()


## Escala px/s no spawn (tiro carregado e feixe; ULT usa `get_chuva_ossos_velocidade_viagem_mul`).
func get_torreta_setup_config() -> Dictionary:
	return {
		"vida": esqueleto_skill_torreta_vida,
		"disparos": esqueleto_skill_torreta_disparos,
		"dano_tiro": esqueleto_skill_torreta_dano_tiro,
		"intervalo_disparo_s": esqueleto_skill_torreta_intervalo_disparo_s,
		"velocidade_tiro": _esqueleto_velocidade_viagem_projetil(min_launch_speed),
	}


func get_torreta_sentinel_setup_config() -> Dictionary:
	return {
		"vida": esqueleto_skill_torreta_sentinela_vida,
		"disparos": esqueleto_skill_torreta_sentinela_disparos,
		"dano_tiro": esqueleto_skill_torreta_sentinela_dano_tiro,
		"intervalo_disparo_s": esqueleto_skill_torreta_sentinela_intervalo_disparo_s,
		"velocidade_tiro": _esqueleto_velocidade_viagem_projetil(min_launch_speed),
		"walk_speed": esqueleto_skill_torreta_sentinela_walk_speed,
		"follow_range": esqueleto_skill_torreta_sentinela_alcance_seguir,
		"preferred_distance": esqueleto_skill_torreta_sentinela_distancia_ideal,
	}


func get_torreta_rocket_setup_config() -> Dictionary:
	return {
		"charge_s": esqueleto_skill_torreta_foguete_carga_s,
		"dano_base": esqueleto_skill_torreta_foguete_dano_base,
		"raio": esqueleto_skill_torreta_foguete_raio,
		"knockback_x": esqueleto_skill_torreta_foguete_knockback_x,
		"knockback_up": esqueleto_skill_torreta_foguete_knockback_up,
		"aceleracao": esqueleto_skill_torreta_foguete_aceleracao,
		"vel_max": esqueleto_skill_torreta_foguete_vel_max,
		"tracking_graus_s": esqueleto_skill_torreta_foguete_tracking_graus_s,
		"ricochetes": esqueleto_skill_torreta_foguete_ricochetes,
		"bonus_dano_por_tiro": esqueleto_skill_torreta_foguete_bonus_dano_por_tiro,
		"bonus_vel_por_tiro": esqueleto_skill_torreta_foguete_bonus_vel_por_tiro,
		"sobrecarga_vel_inimigo": esqueleto_skill_torreta_foguete_sobrecarga_vel_inimigo,
	}


func set_turret_active(active: bool) -> void:
	_torreta_active = active


func get_zumbi_setup_config() -> Dictionary:
	return {
		"vida": esqueleto_skill_zumbi_vida,
		"walk_speed": esqueleto_skill_zumbi_walk_speed,
		"grab_radius": esqueleto_skill_zumbi_grab_radius,
		"slow_mul": esqueleto_skill_zumbi_slow_mul,
		"explosion_radius": esqueleto_skill_zumbi_explosion_radius,
		"explosion_damage": esqueleto_skill_zumbi_explosion_dano,
		"explosion_knockback_x": esqueleto_skill_zumbi_explosion_knockback_x,
		"explosion_knockback_up": esqueleto_skill_zumbi_explosion_knockback_up,
	}


func get_mandibula_setup_config() -> Dictionary:
	return {
		"bite_damage": esqueleto_skill_mandibula_dano_mordida,
		"podridao_damage_per_tick": esqueleto_skill_mandibula_podridao_dano_tick,
		"podridao_duration_s": esqueleto_skill_mandibula_podridao_duracao_s,
		"podridao_tick_interval_s": esqueleto_skill_mandibula_podridao_intervalo_tick_s,
		"emerge_s": esqueleto_skill_mandibula_emergencia_s,
		"chase_duration_s": esqueleto_skill_mandibula_perseguicao_s,
		"chase_speed": esqueleto_skill_mandibula_velocidade_perseguicao,
		"knockback_x": esqueleto_skill_mandibula_knockback_x,
		"knockback_up": esqueleto_skill_mandibula_knockback_up,
		"podridao_slow_mul": esqueleto_skill_mandibula_podridao_slow_mul,
	}


func get_vaso_plant_setup_config() -> Dictionary:
	return {
		"gravity": esqueleto_skill_vaso_gravity,
		"lifetime_s": esqueleto_skill_vaso_planta_duracao_s,
		"bite_radius": esqueleto_skill_vaso_planta_raio_mordida,
		"bite_damage": esqueleto_skill_vaso_planta_dano_mordida,
		"bite_interval_s": esqueleto_skill_vaso_planta_intervalo_mordida_s,
		"putrefacao_stacks_per_bite": esqueleto_skill_vaso_putrefacao_cargas,
		"putrefacao_duration_s": esqueleto_skill_vaso_putrefacao_duracao_s,
		"putrefacao_damage_per_stack": esqueleto_skill_vaso_putrefacao_dano_por_carga,
		"putrefacao_tick_interval_s": esqueleto_skill_vaso_putrefacao_intervalo_tick_s,
	}


func set_zombie_active(active: bool) -> void:
	_zumbi_active = active


func _esqueleto_velocidade_viagem_projetil(speed: float) -> float:
	return speed * get_projetil_velocidade_viagem_mul()


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	_sync_esqueleto_body_sprite(delta)


func should_pass_through_projectile(_projectile: Node) -> bool:
	return _esqueleto_dash_invuln_left > 0.0


func take_damage(amount: int) -> void:
	if _esqueleto_dash_invuln_left > 0.0:
		return
	var was_alive := hp > 0
	super.take_damage(amount)
	if was_alive and hp <= 0:
		_esqueleto_play_action_once("death")


func apply_knockback(knockback: Vector2) -> void:
	if _esqueleto_dash_invuln_left > 0.0:
		return
	super.apply_knockback(knockback)
	if hp > 0 and _sprite_action_lock != "death":
		_esqueleto_play_action_once("hurt")


func _extra_timer_tick(delta: float) -> void:
	super._extra_timer_tick(delta)
	_esqueleto_dash_invuln_left = maxf(0.0, _esqueleto_dash_invuln_left - delta)
	_feixe_cd_restante_s = maxf(0.0, _feixe_cd_restante_s - delta)
	_vaso_cd_restante_s = maxf(0.0, _vaso_cd_restante_s - delta)
	_torreta_cd_restante_s = maxf(0.0, _torreta_cd_restante_s - delta)
	_torreta_evolution_cd_restante_s = maxf(0.0, _torreta_evolution_cd_restante_s - delta)
	_zumbi_cd_restante_s = maxf(0.0, _zumbi_cd_restante_s - delta)
	_mandibula_cd_restante_s = maxf(0.0, _mandibula_cd_restante_s - delta)
	_esqueleto_buff_velocidade_tiro_cd_restante_s = maxf(0.0, _esqueleto_buff_velocidade_tiro_cd_restante_s - delta)
	_auto_mutilacao_cd_restante_s = maxf(0.0, _auto_mutilacao_cd_restante_s - delta)
	_esqueleto_ult_cd_restante_s = maxf(0.0, _esqueleto_ult_cd_restante_s - delta)
	if _esqueleto_chuva_ossos_ativa:
		if _esqueleto_ult_armagem_animacao_restante_s > 0.0:
			if not is_stalled():
				_esqueleto_ult_armagem_animacao_restante_s -= delta
			if _esqueleto_ult_armagem_animacao_restante_s <= 0.0:
				ult_status_changed.emit(true, _esqueleto_chuva_ossos_tempo_restante_s, false)
			else:
				ult_status_changed.emit(true, _esqueleto_ult_armagem_animacao_restante_s, true)
		else:
			_esqueleto_chuva_ossos_tempo_restante_s -= delta
			if _esqueleto_chuva_ossos_tempo_restante_s <= 0.0:
				_finalizar_chuva_ossos()
			else:
				ult_status_changed.emit(true, _esqueleto_chuva_ossos_tempo_restante_s, false)
	if _esqueleto_buff_velocidade_tiro_ativo:
		_esqueleto_buff_velocidade_tiro_tempo_restante_s -= delta
		if _esqueleto_buff_velocidade_tiro_tempo_restante_s <= 0.0:
			_esqueleto_buff_velocidade_tiro_ativo = false
			_refresh_esqueleto_combat_modulate()
			if not _auto_mutilacao_ativo:
				special_buff_changed.emit(false, 0, 0.0)
		else:
			special_buff_changed.emit(true, 1, _esqueleto_buff_velocidade_tiro_tempo_restante_s)
	if _auto_mutilacao_ativo:
		_auto_mutilacao_tempo_restante_s -= delta
		if _auto_mutilacao_tempo_restante_s <= 0.0:
			_auto_mutilacao_ativo = false
			_refresh_esqueleto_combat_modulate()
			if not _esqueleto_buff_velocidade_tiro_ativo:
				special_buff_changed.emit(false, 0, 0.0)
		else:
			special_buff_changed.emit(true, 1, _auto_mutilacao_tempo_restante_s)


func _is_grenade_charging_active() -> bool:
	return _feixe_carregando or _vaso_carregando


func _esqueleto_skill1_charging() -> bool:
	return _feixe_carregando or _vaso_carregando


func _dash_blocked_by_grenade_skill() -> bool:
	return false


func _shoot_charge_blocks_dash() -> bool:
	return false


func uses_dash_action_button() -> bool:
	return _build_skill(EsqueletoBuildCatalog.SLOT_DASH) == EsqueletoBuildCatalog.SKILL_DASH_ACAO


func _air_dash_hold_down_enabled() -> bool:
	return true


func _get_air_dash_diagonal_velocity(speed: float) -> Vector2:
	var rad := deg_to_rad(esqueleto_air_dash_down_angle_deg)
	return Vector2(_dash_dir_sign * speed * cos(rad), speed * sin(rad))


func _air_fast_fall_enabled() -> bool:
	return true


func _get_air_fast_fall_gravity_mul() -> float:
	return esqueleto_fast_fall_gravity_mul


func start_dash_with_direction(dir_sign: float) -> void:
	super.start_dash_with_direction(dir_sign)
	if _dash_time_left > 0.0:
		_esqueleto_dash_invuln_left = esqueleto_dash_invuln_seconds
	if _dash_time_left > 0.0 and hp > 0:
		_esqueleto_begin_dash_sprite()


func _special_uses_left() -> int:
	return 1 if _esqueleto_buff_velocidade_tiro_ativo or _auto_mutilacao_ativo else 0


func get_move_speed_buff_mul() -> float:
	if _auto_mutilacao_ativo:
		return esqueleto_skill_auto_mutilacao_vel_movimento_mul
	return 1.0


func _get_esqueleto_attack_speed_mul() -> float:
	var mul := 1.0
	if _esqueleto_buff_velocidade_tiro_ativo:
		mul *= esqueleto_skill_buff_velocidade_tiro_multiplicador
	if _auto_mutilacao_ativo:
		mul *= esqueleto_skill_auto_mutilacao_vel_ataque_mul
	return mul


func _get_esqueleto_shoot_cooldown_s() -> float:
	return shoot_cooldown / _get_esqueleto_attack_speed_mul()


func _refresh_esqueleto_combat_modulate() -> void:
	if _esqueleto_chuva_ossos_ativa:
		if _esqueleto_ult_armagem_animacao_restante_s > 0.0:
			self.modulate = esqueleto_skill_ult_chuva_ossos_modulate
			return
		if _esqueleto_buff_velocidade_tiro_ativo:
			self.modulate = Color(0.5, 1.5, 2.0)
		elif _auto_mutilacao_ativo:
			self.modulate = Color(1.35, 0.48, 0.52)
		else:
			self.modulate = Color(1, 1, 1)
		return
	if _esqueleto_buff_velocidade_tiro_ativo:
		self.modulate = Color(0.5, 1.5, 2.0)
	elif _auto_mutilacao_ativo:
		self.modulate = Color(1.35, 0.48, 0.52)
	else:
		self.modulate = Color(1, 1, 1)


func _pagar_custo_hp(custo: int) -> bool:
	if custo <= 0:
		return true
	if hp <= custo:
		return false
	hp -= custo
	health_changed.emit(hp)
	_notify_damage_received(custo)
	return true


func _preview_gravity_for_shot() -> float:
	if _vaso_carregando:
		return esqueleto_skill_vaso_gravity
	return 0.0


func _grenade_just_pressed() -> bool:
	if player_id == 1:
		return Input.is_action_just_pressed("p1_grenade")
	return Input.is_action_just_pressed("p2_grenade")


func _grenade_pressed() -> bool:
	return Input.is_action_pressed("p1_grenade" if player_id == 1 else "p2_grenade")


func _grenade_just_released() -> bool:
	return Input.is_action_just_released("p1_grenade" if player_id == 1 else "p2_grenade")


func _ult_just_pressed() -> bool:
	if player_id == 1:
		return Input.is_action_just_pressed("p1_ult")
	return Input.is_action_just_pressed("p2_ult")


func is_chuva_ossos_ativa() -> bool:
	return _esqueleto_chuva_ossos_ativa


## Fases 1–2: acionamento + animação SUPER (parado; sem outras skills).
func is_ult_em_armagem_ou_animacao() -> bool:
	return _esqueleto_chuva_ossos_ativa and _esqueleto_ult_armagem_animacao_restante_s > 0.0


## Fase 3: efeito (chuva de ossos); movimento e skills liberados.
func is_ult_efeito_chuva_ativo() -> bool:
	return _esqueleto_chuva_ossos_ativa and _esqueleto_ult_armagem_animacao_restante_s <= 0.0


func is_buff_velocidade_tiro_ativo() -> bool:
	return _esqueleto_buff_velocidade_tiro_ativo


func get_buff_velocidade_tiro_tempo_restante_s() -> float:
	return _esqueleto_buff_velocidade_tiro_tempo_restante_s


## Termina animação e entra na fase **efeito** (chuva).
func enter_ult_efeito_phase() -> void:
	if not _esqueleto_chuva_ossos_ativa:
		return
	_esqueleto_ult_armagem_animacao_restante_s = 0.0
	_refresh_esqueleto_combat_modulate()
	ult_status_changed.emit(true, _esqueleto_chuva_ossos_tempo_restante_s, false)


func end_ult_super_phase_visual() -> void:
	enter_ult_efeito_phase()


func _finalizar_chuva_ossos() -> void:
	_esqueleto_chuva_ossos_ativa = false
	_esqueleto_chuva_ossos_tempo_restante_s = 0.0
	_refresh_esqueleto_combat_modulate()
	ult_status_changed.emit(false, 0.0, false)


func _tentar_ativar_ult() -> void:
	match _build_skill(EsqueletoBuildCatalog.SLOT_ULT):
		EsqueletoBuildCatalog.SKILL_CHUVA_OSSOS:
			_tentar_ativar_ult_chuva_ossos()
		_:
			push_warning("Esqueleto: ULT desconhecida '%s' — fallback chuva de ossos." % _build_skill(EsqueletoBuildCatalog.SLOT_ULT))
			_tentar_ativar_ult_chuva_ossos()


func _tentar_ativar_ult_chuva_ossos() -> void:
	if not input_enabled or _control_lock_left > 0.0:
		return
	if _esqueleto_ult_cd_restante_s > 0.0 or _esqueleto_chuva_ossos_ativa:
		return
	if _feixe_carregando or _vaso_carregando or _is_charging:
		return
	if not _ult_just_pressed():
		return
	_esqueleto_ult_cd_restante_s = esqueleto_skill_ult_chuva_ossos_recarga_s
	_esqueleto_chuva_ossos_ativa = true
	_esqueleto_ult_armagem_animacao_restante_s = esqueleto_skill_ult_chuva_ossos_fase_armagem_animacao_s
	_esqueleto_chuva_ossos_tempo_restante_s = esqueleto_skill_ult_chuva_ossos_duracao_s
	self.modulate = esqueleto_skill_ult_chuva_ossos_modulate
	ult_status_changed.emit(true, _esqueleto_ult_armagem_animacao_restante_s, true)
	bone_rain_requested.emit(self)


func _feixe_launch_speed(t: float) -> float:
	var speed := _esqueleto_velocidade_viagem_projetil(
		lerpf(
			min_launch_speed * esqueleto_skill_feixe_velocidade_mul_min,
			max_launch_speed * esqueleto_skill_feixe_velocidade_mul_max,
			t
		)
	)
	return speed * _get_esqueleto_attack_speed_mul()


func _refresh_feixe_preview() -> void:
	var t := (
		0.0
		if esqueleto_skill_feixe_tempo_max_carga_s <= 0.0
		else clampf(_feixe_tempo_carga_s / esqueleto_skill_feixe_tempo_max_carga_s, 0.0, 1.0)
	)
	_update_trajectory_preview(_feixe_launch_speed(t))


func _disparar_feixe() -> void:
	var t := (
		0.0
		if esqueleto_skill_feixe_tempo_max_carga_s <= 0.0
		else clampf(_feixe_tempo_carga_s / esqueleto_skill_feixe_tempo_max_carga_s, 0.0, 1.0)
	)
	var speed := _feixe_launch_speed(t)
	var size := lerpf(esqueleto_skill_feixe_escala_min, esqueleto_skill_feixe_escala_max, t)
	var vel := _compute_launch_velocity(speed)
	if vel.length_squared() < 1.0:
		vel = (Vector2.RIGHT * speed) if player_id == 1 else (Vector2.LEFT * speed)
	var dir := vel.normalized()
	var size_spawn := size * esqueleto_projetil_tamanho_mul
	var spawn_pos := muzzle.global_position + dir * (22.0 * size_spawn)
	var shots: Array = [{
		"pos": spawn_pos,
		"vel": vel,
		"gravity": 0.0,
		"bounces": 0,
		"damage": esqueleto_skill_feixe_dano,
		"clash_power": esqueleto_skill_feixe_dano,
		"clash_integrity": esqueleto_skill_feixe_clash_integridade,
		"size": size,
		"flags": {"esqueleto_feixe": true},
	}]
	shots_requested.emit(self, shots)
	_esqueleto_play_action_once("attack")
	var f := esqueleto_skill_feixe_recoil_forca
	var pitch := deg_to_rad(esqueleto_skill_feixe_recoil_angulo_acima_horizontal_graus)
	var back_x_sign := -signf(dir.x) if absf(dir.x) > 0.02 else (-1.0 if player_id == 1 else 1.0)
	var horiz := back_x_sign * f * cos(pitch)
	var vert := -f * sin(pitch)
	add_carry_knockback_x(horiz)
	_apply_velocity_knockback_once(Vector2(0.0, vert))


func _ativar_buff_velocidade_tiro_carregado() -> void:
	_esqueleto_buff_velocidade_tiro_ativo = true
	_esqueleto_buff_velocidade_tiro_tempo_restante_s = esqueleto_skill_buff_velocidade_tiro_duracao_s
	_esqueleto_buff_velocidade_tiro_cd_restante_s = esqueleto_skill_buff_velocidade_tiro_recarga_s
	_refresh_esqueleto_combat_modulate()
	special_buff_changed.emit(true, 1, esqueleto_skill_buff_velocidade_tiro_duracao_s)


func _ativar_auto_mutilacao() -> void:
	if not _pagar_custo_hp(esqueleto_skill_auto_mutilacao_custo_hp):
		return
	_auto_mutilacao_ativo = true
	_auto_mutilacao_tempo_restante_s = esqueleto_skill_auto_mutilacao_duracao_s
	_auto_mutilacao_cd_restante_s = esqueleto_skill_auto_mutilacao_recarga_s
	_refresh_esqueleto_combat_modulate()
	_esqueleto_play_action_once("hurt")
	SfxManager.play("hit_light", global_position, 0.92, -1.0)
	special_buff_changed.emit(true, 1, esqueleto_skill_auto_mutilacao_duracao_s)


func _process_skill_1(delta: float, ult_parado: bool) -> void:
	match _build_skill(EsqueletoBuildCatalog.SLOT_SKILL_1):
		EsqueletoBuildCatalog.SKILL_FEIXE:
			_process_skill_1_feixe(delta, ult_parado)
		EsqueletoBuildCatalog.SKILL_TORRETA:
			_process_torreta(false, ult_parado)
		EsqueletoBuildCatalog.SKILL_ZUMBI:
			_process_zumbi(false, ult_parado)
		EsqueletoBuildCatalog.SKILL_MANDIBULA_ESPECTRAL:
			_process_mandibula(false, ult_parado)
		EsqueletoBuildCatalog.SKILL_VASO_CARNIVORA:
			_process_skill_1_vaso(delta, ult_parado)
		_:
			pass


func _process_skill_1_feixe(delta: float, ult_parado: bool) -> void:
	if input_enabled and _control_lock_left <= 0.0 and not _is_charging and not ult_parado:
		if _feixe_cd_restante_s <= 0.0 and _grenade_just_pressed() and not _vaso_carregando:
			_feixe_carregando = true
			_feixe_tempo_carga_s = 0.0
			charge_bar.visible = true
			charge_bar.value = 0.0
			trajectory.visible = true
			_refresh_feixe_preview()
		if _feixe_carregando and _grenade_pressed():
			_feixe_tempo_carga_s = minf(esqueleto_skill_feixe_tempo_max_carga_s, _feixe_tempo_carga_s + delta)
			var tb := (
				0.0
				if esqueleto_skill_feixe_tempo_max_carga_s <= 0.0
				else (_feixe_tempo_carga_s / esqueleto_skill_feixe_tempo_max_carga_s)
			)
			charge_bar.value = clampf(tb * 100.0, 0.0, 100.0)
			_refresh_feixe_preview()
		if _feixe_carregando and _grenade_just_released():
			_disparar_feixe()
			_feixe_carregando = false
			_feixe_cd_restante_s = esqueleto_skill_feixe_recarga_s
			_hide_charge_trajectory_ui()


func _process_skill_1_vaso(delta: float, ult_parado: bool) -> void:
	if input_enabled and _control_lock_left <= 0.0 and not _is_charging and not ult_parado:
		if _vaso_cd_restante_s <= 0.0 and _grenade_just_pressed() and not _feixe_carregando:
			_vaso_carregando = true
			_vaso_tempo_carga_s = 0.0
			charge_bar.visible = true
			charge_bar.value = 0.0
			trajectory.visible = true
			_refresh_vaso_preview()
		if _vaso_carregando and _grenade_pressed():
			_vaso_tempo_carga_s = minf(
				esqueleto_skill_vaso_tempo_max_carga_s,
				_vaso_tempo_carga_s + delta,
			)
			var tb := (
				0.0
				if esqueleto_skill_vaso_tempo_max_carga_s <= 0.0
				else (_vaso_tempo_carga_s / esqueleto_skill_vaso_tempo_max_carga_s)
			)
			charge_bar.value = clampf(tb * 100.0, 0.0, 100.0)
			_refresh_vaso_preview()
		if _vaso_carregando and _grenade_just_released():
			_disparar_vaso()
			_vaso_carregando = false
			_vaso_cd_restante_s = esqueleto_skill_vaso_recarga_s
			_hide_charge_trajectory_ui()


func _vaso_throw_speed(t: float) -> float:
	return lerpf(esqueleto_skill_vaso_vel_min, esqueleto_skill_vaso_vel_max, clampf(t, 0.0, 1.0))


func _refresh_vaso_preview() -> void:
	var t := (
		0.0
		if esqueleto_skill_vaso_tempo_max_carga_s <= 0.0
		else clampf(_vaso_tempo_carga_s / esqueleto_skill_vaso_tempo_max_carga_s, 0.0, 1.0)
	)
	var lob_deg := launch_angle_degrees + esqueleto_skill_vaso_lob_angulo_graus
	var speed := _vaso_throw_speed(t)
	var v := _compute_launch_velocity_with_angle(speed, lob_deg)
	var p := _trajectory_preview_origin()
	var g := esqueleto_skill_vaso_gravity
	trajectory.clear_points()
	for i in range(trajectory_points):
		trajectory.add_point(to_local(p))
		v.y += g * trajectory_step
		p += v * trajectory_step
		if not get_viewport_rect().has_point(p):
			break


func _disparar_vaso() -> void:
	var t := (
		0.0
		if esqueleto_skill_vaso_tempo_max_carga_s <= 0.0
		else clampf(_vaso_tempo_carga_s / esqueleto_skill_vaso_tempo_max_carga_s, 0.0, 1.0)
	)
	var lob_deg := launch_angle_degrees + esqueleto_skill_vaso_lob_angulo_graus
	var speed := _vaso_throw_speed(t)
	var vel := _compute_launch_velocity_with_angle(speed, lob_deg)
	carnivorous_pot_requested.emit(self, muzzle.global_position, vel)
	_esqueleto_play_action_once("attack")
	SfxManager.play("grenade_throw", global_position, 0.9, -1.0)


func _process_skill_2(ult_parado: bool) -> void:
	match _build_skill(EsqueletoBuildCatalog.SLOT_SKILL_2):
		EsqueletoBuildCatalog.SKILL_BUFF_VELOCIDADE:
			_process_skill_2_buff(ult_parado)
		EsqueletoBuildCatalog.SKILL_AUTO_MUTILACAO:
			_process_skill_2_auto_mutilacao(ult_parado)
		EsqueletoBuildCatalog.SKILL_TORRETA:
			_process_torreta(true, ult_parado)
		EsqueletoBuildCatalog.SKILL_ZUMBI:
			_process_zumbi(true, ult_parado)
		EsqueletoBuildCatalog.SKILL_MANDIBULA_ESPECTRAL:
			_process_mandibula(true, ult_parado)
		_:
			pass


func _process_torreta(use_special_button: bool, ult_parado: bool) -> void:
	if not input_enabled or _control_lock_left > 0.0 or ult_parado:
		return
	if _esqueleto_skill1_charging() or _is_charging:
		return
	var pressed := _special_just_pressed() if use_special_button else _grenade_just_pressed()
	if not pressed:
		return
	if _torreta_active:
		if _torreta_evolution_cd_restante_s <= 0.0:
			if _torreta_sentinel_input_held():
				turret_sentinel_requested.emit(self)
				_torreta_evolution_cd_restante_s = esqueleto_skill_torreta_evolution_recarga_s
				_esqueleto_play_action_once("attack")
				SfxManager.play("grenade_throw", global_position, 0.78, 4.0)
			elif _torreta_rocket_input_held():
				turret_rocket_requested.emit(self)
				_torreta_evolution_cd_restante_s = esqueleto_skill_torreta_evolution_recarga_s
				_esqueleto_play_action_once("attack")
				SfxManager.play("ult_start", global_position, 0.42, -10.0)
		return
	if _torreta_cd_restante_s > 0.0:
		return
	_colocar_torreta()


func _torreta_sentinel_input_held() -> bool:
	var prefix := "p1" if player_id == 1 else "p2"
	# Teclado: W está em hover_up; comando: stick/d-pad em move_up.
	if Input.is_action_pressed(prefix + "_move_up"):
		return true
	if Input.is_action_pressed(prefix + "_hover_up"):
		return true
	if Input.get_axis(prefix + "_move_down", prefix + "_move_up") > 0.35:
		return true
	return Input.get_axis(prefix + "_hover_down", prefix + "_hover_up") > 0.35


func _torreta_rocket_input_held() -> bool:
	var prefix := "p1" if player_id == 1 else "p2"
	# Teclado: S está em hover_down / down; comando: stick/d-pad em move_down.
	if Input.is_action_pressed(prefix + "_move_down"):
		return true
	if Input.is_action_pressed(prefix + "_hover_down"):
		return true
	if Input.is_action_pressed(prefix + "_down"):
		return true
	if Input.get_axis(prefix + "_move_down", prefix + "_move_up") < -0.35:
		return true
	return Input.get_axis(prefix + "_hover_down", prefix + "_hover_up") < -0.35


func _colocar_torreta() -> void:
	_torreta_cd_restante_s = esqueleto_skill_torreta_recarga_s
	var face_sign := 1.0
	if _facing_root != null and absf(_facing_root.scale.x) > 0.01:
		face_sign = signf(_facing_root.scale.x)
	elif player_id == 2:
		face_sign = -1.0
	var spawn_pos := global_position + Vector2(face_sign * esqueleto_skill_torreta_offset_spawn_x, 0.0)
	turret_requested.emit(self, spawn_pos)
	_esqueleto_play_action_once("attack")
	SfxManager.play("grenade_throw", global_position, 0.85, -2.0)


func _process_zumbi(use_special_button: bool, ult_parado: bool) -> void:
	if not input_enabled or _control_lock_left > 0.0 or ult_parado:
		return
	var pressed := _special_just_pressed() if use_special_button else _grenade_just_pressed()
	if not pressed or _esqueleto_skill1_charging() or _is_charging:
		return
	if _zumbi_active:
		zumbi_detonate_requested.emit(self)
		return
	if _zumbi_cd_restante_s > 0.0:
		return
	_invocar_zumbi()


func _invocar_zumbi() -> void:
	_zumbi_cd_restante_s = esqueleto_skill_zumbi_recarga_s
	var face_sign := 1.0
	if _facing_root != null and absf(_facing_root.scale.x) > 0.01:
		face_sign = signf(_facing_root.scale.x)
	elif player_id == 2:
		face_sign = -1.0
	var spawn_pos := global_position + Vector2(face_sign * esqueleto_skill_zumbi_offset_spawn_x, 0.0)
	zumbi_summon_requested.emit(self, spawn_pos)
	_esqueleto_play_action_once("attack")
	SfxManager.play("grenade_throw", global_position, 0.9, 0.0)


func _process_mandibula(use_special_button: bool, ult_parado: bool) -> void:
	if not input_enabled or _control_lock_left > 0.0 or ult_parado:
		return
	if _mandibula_cd_restante_s > 0.0 or _esqueleto_skill1_charging() or _is_charging:
		return
	var pressed := _special_just_pressed() if use_special_button else _grenade_just_pressed()
	if pressed:
		_invocar_mandibula()


func _invocar_mandibula() -> void:
	if AutoAimFiveWayUtil.find_valid_opponent(self) == null:
		return
	_mandibula_cd_restante_s = esqueleto_skill_mandibula_recarga_s
	spectral_jaw_requested.emit(self)
	_esqueleto_play_action_once("attack")
	SfxManager.play("grenade_throw", global_position, 0.88, 4.0)


func _process_skill_2_buff(ult_parado: bool) -> void:
	if input_enabled and _control_lock_left <= 0.0 and not ult_parado:
		if (
			_special_just_pressed()
			and _esqueleto_buff_velocidade_tiro_cd_restante_s <= 0.0
			and not _esqueleto_buff_velocidade_tiro_ativo
		):
			_ativar_buff_velocidade_tiro_carregado()


func _process_skill_2_auto_mutilacao(ult_parado: bool) -> void:
	if input_enabled and _control_lock_left <= 0.0 and not ult_parado:
		if (
			_special_just_pressed()
			and _auto_mutilacao_cd_restante_s <= 0.0
			and not _auto_mutilacao_ativo
			and hp > esqueleto_skill_auto_mutilacao_custo_hp
		):
			_ativar_auto_mutilacao()


func _process_basic_shot(delta: float, ult_parado: bool) -> void:
	match _build_skill(EsqueletoBuildCatalog.SLOT_BASIC_SHOT):
		EsqueletoBuildCatalog.SKILL_TIRO_CARREGADO:
			_process_basic_shot_carregado(delta, ult_parado)
		_:
			pass


func _process_basic_shot_carregado(delta: float, ult_parado: bool) -> void:
	if _cooldown_left <= 0.0 and input_enabled and not _esqueleto_skill1_charging() and not ult_parado:
		if (not _is_charging) and _shoot_just_pressed():
			_is_charging = true
			_charge_time = 0.0
			charge_bar.visible = true
			charge_bar.value = 0.0
			trajectory.visible = true
			_update_trajectory_preview(_esqueleto_velocidade_viagem_projetil(min_launch_speed))

		if _is_charging and _shoot_pressed():
			_charge_time = minf(max_charge_time, _charge_time + delta)
			var t_hold := 0.0 if max_charge_time <= 0.0 else (_charge_time / max_charge_time)
			charge_bar.value = clampf(t_hold * 100.0, 0.0, 100.0)
			var speed_hold := _esqueleto_velocidade_viagem_projetil(
				lerpf(min_launch_speed, max_launch_speed, t_hold)
			)
			_update_trajectory_preview(speed_hold)

		if _is_charging and _shoot_just_released():
			_is_charging = false
			var t := 0.0 if max_charge_time <= 0.0 else (_charge_time / max_charge_time)
			var speed := _esqueleto_velocidade_viagem_projetil(
				lerpf(min_launch_speed, max_launch_speed, t)
			) * _get_esqueleto_attack_speed_mul()
			var v0 := _compute_launch_velocity(speed)
			shoot_requested.emit(self, muzzle.global_position, v0, {})
			_apply_recoil(v0, recoil_normal)
			_esqueleto_play_action_once("attack")
			_cooldown_left = _get_esqueleto_shoot_cooldown_s()
			_hide_charge_trajectory_ui()
	else:
		if _is_charging and not _esqueleto_skill1_charging():
			_is_charging = false
			_hide_charge_trajectory_ui()


func _process_combat(delta: float) -> void:
	if input_enabled and _control_lock_left <= 0.0:
		_tentar_ativar_ult()

	var ult_parado := is_ult_em_armagem_ou_animacao()

	_process_skill_1(delta, ult_parado)
	_process_skill_2(ult_parado)
	_process_basic_shot(delta, ult_parado)


func _extra_reset_for_vs_round() -> void:
	_feixe_cd_restante_s = 0.0
	_feixe_carregando = false
	_feixe_tempo_carga_s = 0.0
	_vaso_cd_restante_s = 0.0
	_vaso_carregando = false
	_vaso_tempo_carga_s = 0.0
	_torreta_cd_restante_s = 0.0
	_torreta_active = false
	_torreta_evolution_cd_restante_s = 0.0
	_zumbi_cd_restante_s = 0.0
	_zumbi_active = false
	_mandibula_cd_restante_s = 0.0
	set_esqueleto_zombie_slow_mul(1.0)
	clear_esqueleto_podridao()
	clear_esqueleto_putrefacao()
	_esqueleto_buff_velocidade_tiro_ativo = false
	_esqueleto_buff_velocidade_tiro_tempo_restante_s = 0.0
	_esqueleto_buff_velocidade_tiro_cd_restante_s = 0.0
	_auto_mutilacao_ativo = false
	_auto_mutilacao_tempo_restante_s = 0.0
	_auto_mutilacao_cd_restante_s = 0.0
	_esqueleto_ult_cd_restante_s = 0.0
	_esqueleto_chuva_ossos_ativa = false
	_esqueleto_ult_armagem_animacao_restante_s = 0.0
	_esqueleto_chuva_ossos_tempo_restante_s = 0.0
	self.modulate = Color(1, 1, 1)
	_last_forward_tap_time_s = -100.0
	_last_back_tap_time_s = -100.0
	_esqueleto_was_on_floor = true
	_esqueleto_dash_invuln_left = 0.0
	special_buff_changed.emit(false, 0, 0.0)
	ult_status_changed.emit(false, 0.0, false)
	_reset_esqueleto_sprite_after_round()


func _setup_esqueleto_body_sprite() -> void:
	_body_sprite = get_node_or_null("FacingRoot/BodySprite") as AnimatedSprite2D
	if _body_sprite == null:
		return
	if not ResourceLoader.exists(ESQUELETO_SPRITE_FRAMES_PATH):
		push_warning("Esqueleto: recurso não encontrado: %s" % ESQUELETO_SPRITE_FRAMES_PATH)
		_show_esqueleto_polygon_fallback()
		return
	var frames := load(ESQUELETO_SPRITE_FRAMES_PATH) as SpriteFrames
	if frames == null or _esqueleto_pick_locomotion_anim(frames) == "":
		push_warning(
			"Esqueleto: falha ao carregar SpriteFrames em %s — confira os PNG em art/skeleton/."
			% ESQUELETO_SPRITE_FRAMES_PATH
		)
		_show_esqueleto_polygon_fallback()
		return
	_body_sprite.sprite_frames = frames
	_body_sprite.visible = true
	_body_sprite.offset = BODY_SPRITE_OFFSET
	_body_sprite.scale = BODY_SPRITE_SCALE
	_body_sprite.flip_h = _esqueleto_default_sprite_flip_h()
	_orig_sprite_modulate = _body_sprite.modulate
	if _body_visual != null:
		_body_visual.visible = false
	if _bow_visual != null:
		_bow_visual.visible = false
	if not _body_sprite.animation_finished.is_connected(_on_esqueleto_sprite_animation_finished):
		_body_sprite.animation_finished.connect(_on_esqueleto_sprite_animation_finished)
	_sprite_action_lock = ""
	_body_sprite.play(_resolve_esqueleto_anim_name(frames, BODY_IDLE_ANIM))


func _show_esqueleto_polygon_fallback() -> void:
	if _body_sprite != null:
		_body_sprite.visible = false
	if _body_visual != null:
		_body_visual.visible = true


func _reset_esqueleto_sprite_after_round() -> void:
	_sprite_action_lock = ""
	if _body_sprite == null or not _body_sprite.visible or _body_sprite.sprite_frames == null:
		return
	_body_sprite.play(_resolve_esqueleto_anim_name(_body_sprite.sprite_frames, BODY_IDLE_ANIM))


func _esqueleto_anim_has_frames(frames: SpriteFrames, anim_name: String) -> bool:
	return frames.has_animation(anim_name) and frames.get_frame_count(anim_name) > 0


func _resolve_esqueleto_anim_name(frames: SpriteFrames, preferred: String) -> String:
	if _esqueleto_anim_has_frames(frames, preferred):
		return preferred
	var aliases: Dictionary = {
		"walk": ["run", "new_animation"],
		"jump": ["jump2"],
		"idle_smoking": ["idle"],
		"idle": ["idle_smoking"],
		"death": ["dead"],
		"attack": ["atack"],
	}
	for alt: String in aliases.get(preferred, []):
		if _esqueleto_anim_has_frames(frames, alt):
			return alt
	for anim_name: String in frames.get_animation_names():
		if anim_name != "default" and _esqueleto_anim_has_frames(frames, anim_name):
			return anim_name
	return preferred


func _esqueleto_pick_locomotion_anim(frames: SpriteFrames) -> String:
	for key: String in [BODY_IDLE_ANIM, "walk"]:
		var name := _resolve_esqueleto_anim_name(frames, key)
		if _esqueleto_anim_has_frames(frames, name):
			return name
	return ""


func _esqueleto_play_action_once(action_key: String) -> void:
	if _body_sprite == null or not _body_sprite.visible or _body_sprite.sprite_frames == null:
		return
	if _sprite_action_lock == "death":
		return
	if hp <= 0 and action_key != "death":
		return
	if action_key == "hurt" and _sprite_action_lock == "attack":
		return
	if action_key == "attack" and _sprite_action_lock == "hurt":
		_sprite_action_lock = ""
	var anim := _resolve_esqueleto_anim_name(_body_sprite.sprite_frames, action_key)
	if not _esqueleto_anim_has_frames(_body_sprite.sprite_frames, anim):
		return
	_sprite_action_lock = action_key
	_body_sprite.play(anim)


func _on_esqueleto_sprite_animation_finished() -> void:
	if _sprite_action_lock == "death":
		return
	if _sprite_action_lock == "dash":
		if _dash_time_left > 0.0 and _body_sprite.sprite_frames != null:
			var dash_anim := _resolve_esqueleto_anim_name(_body_sprite.sprite_frames, BODY_DASH_ANIM)
			_body_sprite.play(dash_anim)
		else:
			_sprite_action_lock = ""
		return
	if _sprite_action_lock == "jump":
		if not is_on_floor():
			_esqueleto_hold_jump_last_frame()
		return
	if _sprite_action_lock in ["hurt", "attack"]:
		_sprite_action_lock = ""
		if not is_on_floor():
			_esqueleto_hold_jump_last_frame()
		return


func _esqueleto_default_sprite_flip_h() -> bool:
	return _resolve_sprite_flip_h()


func _esqueleto_dash_sprite_flip_h() -> bool:
	if RunConfig.is_lock_on_face_test() and _lock_on_face_active and _lock_on_target != null:
		return _resolve_sprite_flip_h()
	var forward_sign := 1.0 if player_id == 1 else -1.0
	return absf(_dash_dir_sign - forward_sign) > 0.001


func _esqueleto_begin_dash_sprite() -> void:
	if _body_sprite == null or not _body_sprite.visible or _body_sprite.sprite_frames == null:
		return
	if _sprite_action_lock == "death":
		return
	var anim := _resolve_esqueleto_anim_name(_body_sprite.sprite_frames, BODY_DASH_ANIM)
	if not _esqueleto_anim_has_frames(_body_sprite.sprite_frames, anim):
		return
	_sprite_action_lock = "dash"
	_body_sprite.flip_h = _esqueleto_dash_sprite_flip_h()
	_body_sprite.speed_scale = 1.0
	_body_sprite.play(anim)


func _esqueleto_end_dash_sprite_if_needed() -> void:
	if _sprite_action_lock != "dash":
		return
	if _dash_time_left > 0.0:
		return
	_sprite_action_lock = ""
	if _body_sprite != null:
		_body_sprite.flip_h = _esqueleto_default_sprite_flip_h()
	if not is_on_floor():
		_esqueleto_hold_jump_last_frame()


func _esqueleto_begin_jump_sprite() -> void:
	if _body_sprite == null or not _body_sprite.visible or _body_sprite.sprite_frames == null:
		return
	if _sprite_action_lock in ["death", "dash", "hurt", "attack"]:
		return
	var anim := _resolve_esqueleto_anim_name(_body_sprite.sprite_frames, BODY_JUMP_ANIM)
	if not _esqueleto_anim_has_frames(_body_sprite.sprite_frames, anim):
		return
	_sprite_action_lock = "jump"
	_body_sprite.flip_h = _esqueleto_default_sprite_flip_h()
	_body_sprite.speed_scale = 1.0
	_body_sprite.play(anim)


func _esqueleto_hold_jump_last_frame() -> void:
	if _body_sprite == null or not _body_sprite.visible or _body_sprite.sprite_frames == null:
		return
	var anim := _resolve_esqueleto_anim_name(_body_sprite.sprite_frames, BODY_JUMP_ANIM)
	if not _esqueleto_anim_has_frames(_body_sprite.sprite_frames, anim):
		return
	_sprite_action_lock = "jump"
	_body_sprite.flip_h = _esqueleto_default_sprite_flip_h()
	_body_sprite.play(anim)
	_body_sprite.frame = _body_sprite.sprite_frames.get_frame_count(anim) - 1
	_body_sprite.pause()


func _esqueleto_update_jump_sprite_state() -> void:
	if is_on_floor():
		if _sprite_action_lock == "jump":
			_sprite_action_lock = ""
		_esqueleto_was_on_floor = true
		return
	if _esqueleto_was_on_floor:
		_esqueleto_was_on_floor = false
		_esqueleto_begin_jump_sprite()
	elif _jump_just_pressed():
		_esqueleto_begin_jump_sprite()


func _esqueleto_locomotion_anim() -> String:
	if is_ult_em_armagem_ou_animacao():
		return BODY_IDLE_ANIM
	if is_on_floor() and absf(velocity.x) > BODY_MOVE_SPEED_THRESHOLD:
		return "walk"
	return BODY_IDLE_ANIM


func _sync_esqueleto_body_sprite(_delta: float) -> void:
	if _body_sprite == null or not _body_sprite.visible or _body_sprite.sprite_frames == null:
		return
	_esqueleto_end_dash_sprite_if_needed()
	_esqueleto_update_jump_sprite_state()
	var frames := _body_sprite.sprite_frames
	if hp <= 0:
		if _sprite_action_lock != "death":
			_esqueleto_play_action_once("death")
		_apply_esqueleto_sprite_modulate()
		return
	if _sprite_action_lock == "dash":
		var dash_anim := _resolve_esqueleto_anim_name(frames, BODY_DASH_ANIM)
		if _body_sprite.animation != dash_anim or not _body_sprite.is_playing():
			_body_sprite.play(dash_anim)
		_body_sprite.flip_h = _esqueleto_dash_sprite_flip_h()
		_body_sprite.speed_scale = 1.0
		_apply_esqueleto_sprite_modulate()
		return
	if _sprite_action_lock == "jump":
		_apply_esqueleto_sprite_modulate()
		return
	if _sprite_action_lock != "":
		_apply_esqueleto_sprite_modulate()
		return
	var want := _resolve_esqueleto_anim_name(frames, _esqueleto_locomotion_anim())
	if not _esqueleto_anim_has_frames(frames, want):
		return
	if _body_sprite.animation != want or not _body_sprite.is_playing():
		_body_sprite.play(want)
	var walk_name := _resolve_esqueleto_anim_name(frames, "walk")
	_body_sprite.speed_scale = 1.28 if want == walk_name and _is_sprint_speed_boost_active() else 1.0
	_apply_esqueleto_sprite_modulate()


func _refresh_character_body_modulate() -> void:
	_apply_esqueleto_sprite_modulate()


func _apply_esqueleto_sprite_modulate() -> void:
	if _body_sprite == null:
		return
	if _frozen_left > 0.0:
		_body_sprite.modulate = Color(0.75, 0.9, 1.0, 1.0)
	elif has_esqueleto_podridao():
		_body_sprite.modulate = get_esqueleto_podridao_body_color()
	elif has_esqueleto_putrefacao():
		_body_sprite.modulate = get_esqueleto_putrefacao_body_color()
	elif _is_sprint_speed_boost_active():
		_body_sprite.modulate = _orig_sprite_modulate * sprint_visual_body_mult
	else:
		_body_sprite.modulate = _orig_sprite_modulate
