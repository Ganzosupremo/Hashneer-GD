# Sistema de skills

Cada skill es **un archivo `.tres`** con el script `SkillDefinition` dentro de `Resources/Skills/`. Las subcarpetas también cuentan: `Stats/`, `Weapons/` y `Abilities/` son solo para ordenar. Al arrancar, `SkillProgress` (autoload) carga todos esos archivos y el árbol se arma solo. No hay que registrar nada en ningún otro lado.

## Cómo funciona

| Pieza | Qué hace |
|---|---|
| `SkillDefinition` (`Scripts/Skills/SkillDefinition.gd`) | Los datos de una skill: id, nombre, ícono, rama, modos, requisitos, efectos y costos. |
| `SkillEffect` (`Scripts/Skills/Effects/`) | Lo que hace la skill. Hay tres tipos: `StatSkillEffect`, `UnlockWeaponSkillEffect` y `UnlockAbilitySkillEffect`. |
| `SkillRequirement` | La skill X tiene que llegar al nivel N antes de poder comprar esta. |
| `SkillProgress` (autoload) | Compra niveles, calcula precios (inflación, halvings, eventos económicos) y guarda **solo** `{id: nivel}` en la clave `skill_progress`. |
| `PlayerLoadout` | Lo que dan las skills en un modo: stats, armas y habilidades. Se recalcula cada vez que empieza un modo con `SkillProgress.build_loadout(modo)`. |
| `SkillTreeView` / `SkillTreeNode` / `SkillDetailPanel` (`Scripts/Skills/UI/`) | La UI: una columna por rama, una fila por tier, y el panel de la izquierda para comprar. |

Como nada se guarda dos veces, si cambiás un valor en un `.tres` (por ejemplo, la vida por nivel), las partidas existentes también lo ven.

## Agregar una skill de stat

1. En el FileSystem del editor: clic derecho sobre `Resources/Skills/Stats/` → **New Resource…** → `SkillDefinition`.
2. Completá **Identity**: `id` (único, en snake_case, y no lo cambies después porque es la clave del guardado), `display_name`, `description` e `icon`.
3. En **Tree**, elegí la `branch` (columna). Dejá `tier` en -1 para que quede una fila debajo de su requisito más profundo.
4. En **Game Modes**, marcá Mining, Waves o los dos.
5. En **Requirements**, agregá un `SkillRequirement` y arrastrá el `.tres` de la skill que tiene que comprarse antes, con su `min_level`. Si no ponés requisitos, la skill está disponible desde el inicio. `requires_all` decide si basta con uno de los requisitos o hacen falta todos.
6. En **Effects**, agregá un `StatSkillEffect`: `stat` (Health, Speed, Damage), `is_percentage` (0.1 = +10%), `value_per_level` y `value_multiplier` (1.0 da lo mismo en cada nivel).
7. En **Cost**, completá `max_level` y los precios base y multiplicadores en fiat y BTC.

## Agregar un arma

1. Creá el `WeaponDetails` del arma como siempre, en `Resources/Weapons/Player/`.
2. Creá una `SkillDefinition` en `Resources/Skills/Weapons/` con un `UnlockWeaponSkillEffect` y arrastrá el `WeaponDetails` a `weapon`.

Con eso el arma aparece en el árbol y en la Armería al comprarla, y también en el Feature Tester (F1). No hace falta tocar `Constants.WeaponNames` ni ningún diccionario.

## Agregar una habilidad

1. Creá la escena con raíz `BaseAbility` en `Scenes/Player/Abilities/`.
2. Creá una `SkillDefinition` en `Resources/Skills/Abilities/` con un `UnlockAbilitySkillEffect`: `ability_scene` y `ability_name`.

## Skills por modo

`modes` es un flag. El jugador compra la skill una sola vez, y sus efectos solo se aplican en los modos marcados. En el árbol, cada nodo muestra una insignia **M** (Mining) y/o **W** (Waves), y el filtro *Show* del panel atenúa las skills que no sirven en el modo elegido.

Para agregar un modo nuevo:

1. Agregá el flag en `Constants.GameModeFlag`.
2. Agregalo al `@export_flags` de `SkillDefinition.modes`.
3. Agregale a la escena del modo una función `get_skill_mode() -> int` que devuelva ese flag (como en `MiningGameMode.gd` y `WavesGameMode.gd`).

## Otros tipos de efecto

Creá un script que extienda `SkillEffect` y sobrescribí `apply(loadout, level)` y `describe(level)`. Si el efecto necesita datos nuevos en el loadout (por ejemplo, "+10% de BTC dropeado"), agregá el campo en `PlayerLoadout` y leelo desde el sistema que lo usa.

## Ramas nuevas

Agregá el nombre al `@export_enum` de `SkillDefinition.branch` y, si querés fijar su orden, también a `SkillTreeView.BRANCH_ORDER`.

## Partidas viejas

El árbol anterior guardaba una entrada por nodo (por ejemplo, `PlayerHealthUpgradeFiatT1`) y además los bonus ya sumados en `player_stats`. Al cargar una partida sin `skill_progress`, `SkillProgress` lee el nivel de cada `legacy_save_key`, lo pasa al `id` nuevo y borra la clave vieja. Las skills nuevas no necesitan `legacy_save_key`.

## Feature Tester (F1)

En el menú del árbol, el grupo **Skills (saved)** tiene *Max All Skills*, *+1 Level To Unlocked* (multiplicado por Quantity) y *Reset All Skills*.
