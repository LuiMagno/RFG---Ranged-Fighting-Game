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
@export var esqueleto_skill_feixe_velocidade_mul_min: float = 1.05
@export var esqueleto_skill_feixe_velocidade_mul_max: float = 1.42
## Recoil do feixe: horizontal em `add_carry_knockback_x` (sobrevive ao `velocity.x = dir*speed` no próximo frame); vertical **uma vez** em `velocity` — arco baixo pela gravidade.
@export_range(5.0, 16.0, 0.5) var esqueleto_skill_feixe_recoil_angulo_acima_horizontal_graus: float = 10.0
@export_range(500.0, 1200.0, 10.0) var esqueleto_skill_feixe_recoil_forca: float = 2000.0

## Skill Esqueleto — Buff de velocidade (`*_special`; tiro carregado + feixe)
@export var esqueleto_skill_buff_velocidade_tiro_duracao_s: float = 4.0
@export var esqueleto_skill_buff_velocidade_tiro_recarga_s: float = 10.0
@export var esqueleto_skill_buff_velocidade_tiro_multiplicador: float = 2.0

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

var _esqueleto_buff_velocidade_tiro_ativo := false
var _esqueleto_buff_velocidade_tiro_tempo_restante_s := 0.0
var _esqueleto_buff_velocidade_tiro_cd_restante_s := 0.0
var _feixe_cd_restante_s := 0.0
var _feixe_carregando := false
var _feixe_tempo_carga_s := 0.0
var _esqueleto_ult_cd_restante_s := 0.0
var _esqueleto_chuva_ossos_ativa := false
var _esqueleto_ult_armagem_animacao_restante_s := 0.0
var _esqueleto_chuva_ossos_tempo_restante_s := 0.0

var _body_sprite: AnimatedSprite2D
var _orig_sprite_modulate: Color = Color.WHITE
## Bloqueia troca para idle/walk enquanto hurt/attack/death/dash/jump não terminam.
var _sprite_action_lock := ""
var _esqueleto_was_on_floor := true


func is_esqueleto() -> bool:
	return true


func _ready() -> void:
	shoot_cooldown = maxf(MIN_SHOOT_COOLDOWN_S, shoot_cooldown)
	super._ready()
	_setup_esqueleto_body_sprite()


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
func _esqueleto_velocidade_viagem_projetil(speed: float) -> float:
	return speed * get_projetil_velocidade_viagem_mul()


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	_sync_esqueleto_body_sprite(delta)


func take_damage(amount: int) -> void:
	var was_alive := hp > 0
	super.take_damage(amount)
	if was_alive and hp <= 0:
		_esqueleto_play_action_once("death")


func apply_knockback(knockback: Vector2) -> void:
	super.apply_knockback(knockback)
	if hp > 0 and _sprite_action_lock != "death":
		_esqueleto_play_action_once("hurt")


func _extra_timer_tick(delta: float) -> void:
	_feixe_cd_restante_s = maxf(0.0, _feixe_cd_restante_s - delta)
	_esqueleto_buff_velocidade_tiro_cd_restante_s = maxf(0.0, _esqueleto_buff_velocidade_tiro_cd_restante_s - delta)
	_esqueleto_ult_cd_restante_s = maxf(0.0, _esqueleto_ult_cd_restante_s - delta)
	if _esqueleto_chuva_ossos_ativa:
		if _esqueleto_ult_armagem_animacao_restante_s > 0.0:
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
			self.modulate = Color(1, 1, 1)
			special_buff_changed.emit(false, 0, 0.0)
		else:
			special_buff_changed.emit(true, 1, _esqueleto_buff_velocidade_tiro_tempo_restante_s)


func _is_grenade_charging_active() -> bool:
	return _feixe_carregando


func _dash_blocked_by_grenade_skill() -> bool:
	return false


func uses_dash_action_button() -> bool:
	return true


func start_dash_with_direction(dir_sign: float) -> void:
	super.start_dash_with_direction(dir_sign)
	if _dash_time_left > 0.0 and hp > 0:
		_esqueleto_begin_dash_sprite()


func _special_uses_left() -> int:
	return 1 if _esqueleto_buff_velocidade_tiro_ativo else 0


func _preview_gravity_for_shot() -> float:
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
	if _esqueleto_buff_velocidade_tiro_ativo:
		self.modulate = Color(0.5, 1.5, 2.0)
	else:
		self.modulate = Color(1, 1, 1)
	ult_status_changed.emit(true, _esqueleto_chuva_ossos_tempo_restante_s, false)


func end_ult_super_phase_visual() -> void:
	enter_ult_efeito_phase()


func _finalizar_chuva_ossos() -> void:
	_esqueleto_chuva_ossos_ativa = false
	_esqueleto_chuva_ossos_tempo_restante_s = 0.0
	if _esqueleto_buff_velocidade_tiro_ativo:
		self.modulate = Color(0.5, 1.5, 2.0)
	else:
		self.modulate = Color(1, 1, 1)
	ult_status_changed.emit(false, 0.0, false)


func _tentar_ativar_ult_chuva_ossos() -> void:
	if not input_enabled or _control_lock_left > 0.0:
		return
	if _esqueleto_ult_cd_restante_s > 0.0 or _esqueleto_chuva_ossos_ativa:
		return
	if _feixe_carregando or _is_charging or _esqueleto_buff_velocidade_tiro_ativo:
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
	if _esqueleto_buff_velocidade_tiro_ativo:
		speed *= esqueleto_skill_buff_velocidade_tiro_multiplicador
	return speed


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
	var spawn_pos := muzzle.global_position + dir * (22.0 * size)
	var shots: Array = [{
		"pos": spawn_pos,
		"vel": vel,
		"gravity": 0.0,
		"bounces": 0,
		"damage": esqueleto_skill_feixe_dano,
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
	self.modulate = Color(0.5, 1.5, 2.0)
	special_buff_changed.emit(true, 1, esqueleto_skill_buff_velocidade_tiro_duracao_s)


func _process_combat(delta: float) -> void:
	if input_enabled and _control_lock_left <= 0.0:
		_tentar_ativar_ult_chuva_ossos()

	var ult_parado := is_ult_em_armagem_ou_animacao()

	if input_enabled and _control_lock_left <= 0.0 and not _is_charging and not ult_parado:
		if _feixe_cd_restante_s <= 0.0 and _grenade_just_pressed() and not _feixe_carregando:
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

		if input_enabled and _control_lock_left <= 0.0 and not ult_parado:
			if (
				_special_just_pressed()
				and _esqueleto_buff_velocidade_tiro_cd_restante_s <= 0.0
				and not _esqueleto_buff_velocidade_tiro_ativo
			):
				_ativar_buff_velocidade_tiro_carregado()

	if _cooldown_left <= 0.0 and input_enabled and not _feixe_carregando and not ult_parado:
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
			)
			if _esqueleto_buff_velocidade_tiro_ativo:
				speed *= esqueleto_skill_buff_velocidade_tiro_multiplicador
			var v0 := _compute_launch_velocity(speed)
			shoot_requested.emit(self, muzzle.global_position, v0, {})
			_apply_recoil(v0, recoil_normal)
			_esqueleto_play_action_once("attack")
			_cooldown_left = shoot_cooldown
			_hide_charge_trajectory_ui()
	else:
		if _is_charging and not _feixe_carregando:
			_is_charging = false
			_hide_charge_trajectory_ui()


func _extra_reset_for_vs_round() -> void:
	_feixe_cd_restante_s = 0.0
	_feixe_carregando = false
	_feixe_tempo_carga_s = 0.0
	_esqueleto_buff_velocidade_tiro_ativo = false
	_esqueleto_buff_velocidade_tiro_tempo_restante_s = 0.0
	_esqueleto_buff_velocidade_tiro_cd_restante_s = 0.0
	_esqueleto_ult_cd_restante_s = 0.0
	_esqueleto_chuva_ossos_ativa = false
	_esqueleto_ult_armagem_animacao_restante_s = 0.0
	_esqueleto_chuva_ossos_tempo_restante_s = 0.0
	self.modulate = Color(1, 1, 1)
	_last_forward_tap_time_s = -100.0
	_last_back_tap_time_s = -100.0
	_esqueleto_was_on_floor = true
	special_buff_changed.emit(false, 0, 0.0)
	ult_status_changed.emit(false, 0.0, false)
	_reset_esqueleto_sprite_after_round()


func _setup_esqueleto_body_sprite() -> void:
	_body_sprite = get_node_or_null("BodySprite") as AnimatedSprite2D
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
	return player_id == 2


func _esqueleto_dash_sprite_flip_h() -> bool:
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


func _apply_esqueleto_sprite_modulate() -> void:
	if _body_sprite == null:
		return
	if _frozen_left > 0.0:
		_body_sprite.modulate = Color(0.75, 0.9, 1.0, 1.0)
	elif _is_sprint_speed_boost_active():
		_body_sprite.modulate = _orig_sprite_modulate * sprint_visual_body_mult
	else:
		_body_sprite.modulate = _orig_sprite_modulate
