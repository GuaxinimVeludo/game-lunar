# Protótipo 2.5D Run and Gun (Godot 4)

Projeto inicial executável para uma cena 3D com gameplay no plano XY e profundidade travada em Z=0. O eixo Y segue a convenção 3D da Godot: gravidade para baixo e pulo positivo.

## Abrir e executar

1. Instale/abra Godot 4.
2. No Project Manager, escolha **Import** e selecione este `project.godot`.
3. Abra o projeto; a cena inicial `scenes/main.tscn` monta um campo de teste com jogador, veículo, caixa destrutível e chefe.
4. Pressione **F6** para executar a cena ou **F5** para executar o projeto.

Os controles são criados pelo `InputBootstrap` ao iniciar. Movimento: A/D ou setas; pulo: W/Espaço; agachar: S/↓; atirar: J; faca: K; entrar/sair: E; mirar: setas ou teclado numérico 4/5/6/8. Para usar lança-foguetes, troque o `WeaponData` do veículo no Inspector.

## Hierarquia da cena de demonstração

```text
Main (Node3D)
├── InputBootstrap
├── World
│   ├── Floor (StaticBody3D, layer 1; BoxShape3D)
│   └── DirectionalLight3D
├── Player (CharacterBody3D, layer 2; CapsuleShape3D)
│   ├── CollisionShape3D
│   └── TorsoPivot
│       ├── Torso / Head
│       ├── ArmPivot / Arm
│       └── WeaponController [WeaponData: rifle.tres]
│           └── Muzzle (Marker3D)
├── Vehicles/Jeep (CharacterBody3D, layer 6; BoxShape3D)
│   ├── CollisionShape3D
│   ├── Seat (Marker3D)
│   └── WeaponController [WeaponData: rocket_launcher.tres]
├── Props/Crate (StaticBody3D, layer 7; BoxShape3D)
├── Boss (CharacterBody3D, layer 3; CapsuleShape3D)
│   ├── CollisionShape3D
│   ├── Muzzle (Marker3D)
│   └── Telegraph (MeshInstance3D)
├── Projectiles (Node3D)
└── Camera3D (ortográfica, voltada para +XY a partir de Z positivo)
```

Máscaras do protótipo: jogador 101 (mundo, inimigo, veículo, prop); rifle/foguete 101; chefe 1 (mundo); projétil do chefe 2 (jogador); veículo 5 (mundo e inimigo). Os números são bitmasks: layer 1 = 1, layer 2 = 2, layer 3 = 4, layer 4 = 8, layer 5 = 16, layer 6 = 32, layer 7 = 64.

## Scripts

- `scripts/player_controller.gd` owns movement, health, aim and state transitions.
- `scripts/player_states.gd` contains the base state and Idle, Run, Jump, Crouch, MeleeAttack and VehicleMode states.
- `scripts/weapon_data.gd` is the editable Resource for each weapon.
- `scripts/weapon_controller.gd` handles eight-way aim, hitscan, ballistic and explosive shots.
- `scripts/projectile.gd` handles physical projectiles and area damage.
- `scripts/destructible_prop.gd` is a reusable health component for props.
- `scripts/vehicle_controller.gd` implements enter/drive/eject and independent vehicle health.
- `scripts/boss_ai_controller.gd` selects attacks from distance and health stage, with a visible telegraph.

Para adaptar, edite os Resources em `resources/` e as cenas em `scenes/`. Os campos exportados podem ser alterados no Inspector. O código fixa Z em zero para Player e Vehicle.
