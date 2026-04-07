Z-Spawn AI: A Lightweight NPC & Spawn Manager for Roblox
Most NPC systems in Roblox are either too heavy for performance or too basic to be useful. Z-Spawn AI is a modular, OOP-based solution designed to handle enemy spawning and AI logic without the overhead. It’s built for developers who need a reliable way to manage waves of enemies across different "Stages" with built-in pathfinding and combat states.

What’s Under the Hood?
Smart Proximity Spawning: Instead of just dumping enemies on the map, this system uses weighted probabilities. You can set specific "Stage" folders, and the manager will decide whether to spawn a Normal, Master, or Boss zombie based on the odds you define.

State-Based AI: Every enemy runs on a logic loop that switches between Idle, Move, and Attack. It’s not just a "Follow" script—it uses Raycasting to verify line-of-sight and PathfindingService to navigate around obstacles.

Built-in Hitbox Logic: No need to mess with complex combat scripts. The module handles damage frames and hit detection via a dynamic hitbox, making it easy to tweak damage values for different enemy tiers.

Automatic Cleanup: Includes a background auto-reset feature to clear out stuck or old NPCs, keeping your server’s heartbeat stable during long sessions.

Developer Friendly: The code is strictly organized using Object-Oriented Programming (OOP). You can easily drop this into your ServerStorage, tweak the StageProbabilities table, and have a functioning horde system in minutes.

Quick Setup
Map your spawn points in a folder named EnemySpawnPoints.

Organize your zombie models in ReplicatedFirst (or tweak the path in the script).

Require the module and call .new() to fire up the engine.

Licensing
Released under the MIT License. Feel free to fork it, gut it, or use it in your commercial projects.

Maintained by: Hero
