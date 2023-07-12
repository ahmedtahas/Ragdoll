extends MultiplayerSynchronizer


func sync() -> void:
	replication_config.add_property((".:head_pos") as NodePath)
	replication_config.add_property((".:head_rot") as NodePath)

	replication_config.add_property((".:body_pos") as NodePath)
	replication_config.add_property((".:body_rot") as NodePath)

	replication_config.add_property((".:rua_pos") as NodePath)
	replication_config.add_property((".:rua_rot") as NodePath)
	replication_config.add_property((".:rla_pos") as NodePath)
	replication_config.add_property((".:rla_rot") as NodePath)
	replication_config.add_property((".:rf_pos") as NodePath)
	replication_config.add_property((".:rf_rot") as NodePath)

	replication_config.add_property((".:lua_pos") as NodePath)
	replication_config.add_property((".:lua_rot") as NodePath)
	replication_config.add_property((".:lla_pos") as NodePath)
	replication_config.add_property((".:lla_rot") as NodePath)
	replication_config.add_property((".:lf_pos") as NodePath)
	replication_config.add_property((".:lf_rot") as NodePath)

	replication_config.add_property((".:hip_pos") as NodePath)
	replication_config.add_property((".:hip_rot") as NodePath)

	replication_config.add_property((str(get_parent().get_path()) + ":rul_pos") as NodePath)
	replication_config.add_property((str(get_parent().get_path()) + ":rul_rot") as NodePath)
	replication_config.add_property((str(get_parent().get_path()) + ":rll_pos") as NodePath)
	replication_config.add_property((str(get_parent().get_path()) + ":rll_rot") as NodePath)
	replication_config.add_property((str(get_parent().get_path()) + ":rk_pos") as NodePath)
	replication_config.add_property((str(get_parent().get_path()) + ":rk_rot") as NodePath)

	replication_config.add_property((".:lul_pos") as NodePath)
	replication_config.add_property((".:lul_rot") as NodePath)
	replication_config.add_property((".:lll_pos") as NodePath)
	replication_config.add_property((".:lll_rot") as NodePath)
	replication_config.add_property((".:lk_pos") as NodePath)
	replication_config.add_property((".:lk_rot") as NodePath)
	
	
	
