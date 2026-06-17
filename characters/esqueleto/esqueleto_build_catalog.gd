extends RefCounted
class_name EsqueletoBuildCatalog

## Slots da build modular do Esqueleto (menus + runtime).
const SLOT_SKILL_1 := &"skill_1"
const SLOT_SKILL_2 := &"skill_2"
const SLOT_BASIC_SHOT := &"basic_shot"
const SLOT_DASH := &"dash"
const SLOT_ULT := &"ult"

## IDs estáveis — novas skills entram no catálogo do slot correspondente.
const SKILL_FEIXE := &"feixe"
const SKILL_BUFF_VELOCIDADE := &"buff_velocidade_tiro"
const SKILL_TIRO_CARREGADO := &"tiro_carregado"
const SKILL_DASH_ACAO := &"dash_acao"
const SKILL_CHUVA_OSSOS := &"chuva_ossos"
const SKILL_MIRROR_IMAGE := &"mirror_image"
const SKILL_TORRETA := &"torreta"
const SKILL_ZUMBI := &"zumbi"
const SKILL_MANDIBULA_ESPECTRAL := &"mandibula_espectral"
const SKILL_AUTO_MUTILACAO := &"auto_mutilacao"
const SKILL_VASO_CARNIVORA := &"vaso_carnivora"

const ALL_SLOTS: Array[StringName] = [
	SLOT_SKILL_1,
	SLOT_SKILL_2,
	SLOT_BASIC_SHOT,
	SLOT_DASH,
	SLOT_ULT,
]


static func get_default_build() -> Dictionary:
	return {
		SLOT_SKILL_1: SKILL_FEIXE,
		SLOT_SKILL_2: SKILL_BUFF_VELOCIDADE,
		SLOT_BASIC_SHOT: SKILL_TIRO_CARREGADO,
		SLOT_DASH: SKILL_DASH_ACAO,
		SLOT_ULT: SKILL_CHUVA_OSSOS,
	}


static func get_default_skill_for_slot(slot_key: StringName) -> StringName:
	var defaults := get_default_build()
	if defaults.has(slot_key):
		return defaults[slot_key]
	return &""


static func get_slot_label(slot_key: StringName) -> String:
	match slot_key:
		SLOT_SKILL_1:
			return "Skill 1 (F / X)"
		SLOT_SKILL_2:
			return "Skill 2 (G / Y)"
		SLOT_BASIC_SHOT:
			return "Tiro basico (RB / mouse)"
		SLOT_DASH:
			return "Dash (Shift / B)"
		SLOT_ULT:
			return "ULT (R / LB)"
		_:
			return "Slot"


static func get_slot_options(slot_key: StringName) -> Array[Dictionary]:
	match slot_key:
		SLOT_SKILL_1:
			return [
				{"id": SKILL_FEIXE, "label": "Feixe (carregar + soltar)"},
				{"id": SKILL_VASO_CARNIVORA, "label": "Vaso carnivoro"},
				{"id": SKILL_TORRETA, "label": "Torreta"},
				{"id": SKILL_ZUMBI, "label": "Zumbi"},
				{"id": SKILL_MANDIBULA_ESPECTRAL, "label": "Mandibula espectral"},
			]
		SLOT_SKILL_2:
			return [
				{"id": SKILL_BUFF_VELOCIDADE, "label": "Buff velocidade tiro"},
				{"id": SKILL_AUTO_MUTILACAO, "label": "Auto mutilacao"},
				{"id": SKILL_TORRETA, "label": "Torreta"},
				{"id": SKILL_ZUMBI, "label": "Zumbi"},
				{"id": SKILL_MANDIBULA_ESPECTRAL, "label": "Mandibula espectral"},
			]
		SLOT_BASIC_SHOT:
			return [{"id": SKILL_TIRO_CARREGADO, "label": "Tiro carregado (baseline)"}]
		SLOT_DASH:
			return [{"id": SKILL_DASH_ACAO, "label": "Dash por botao (Shift / B)"}]
		SLOT_ULT:
			return [
				{"id": SKILL_CHUVA_OSSOS, "label": "Chuva de ossos"},
				{"id": SKILL_MIRROR_IMAGE, "label": "Mirror Image"},
			]
		_:
			return []


static func is_valid_skill_for_slot(slot_key: StringName, skill_id: StringName) -> bool:
	for opt in get_slot_options(slot_key):
		if opt.get("id", &"") == skill_id:
			return true
	return false


static func resolve_skill_for_slot(slot_key: StringName, skill_id: StringName) -> StringName:
	if is_valid_skill_for_slot(slot_key, skill_id):
		return skill_id
	return get_default_skill_for_slot(slot_key)
