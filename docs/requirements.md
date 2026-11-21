# Requirements: Cities of Progress

Status: draft for review, 2026-11-18.

Cities of Progress is a co-operative strategy game for macOS, for one to three people. This document states what the game must do. It contains no design: no language, library, network method, file layout or artwork decision. Those wait until the requirements are reviewed.

## Purpose

A real-time strategy game in the genre of the original Age of Empires, for personal play. One to three people on the same local network, each at a Mac, play as allies against computer players.

## Terms

- **Player:** one participant in a match, human or computer, with a base of its own.
- **Civilization:** what a player plays as (Sumer or Rome, for example); it gives the player a name and a colour.
- **Team:** a group of players who are allies. A team may consist of one player.
- **Ally:** another player on the same team.
- **Economy:** a group of related resources and the means of obtaining them (food, or energy, for example).
- **Sector:** one of the kinds of people in a civilization, defined by what they do (workers or scholars, for example).

## Stated requirements

These come from the person for whom the game is made and are settled.

1. The game is called Cities of Progress.
2. The game plays like the original Age of Empires: the player directs people to gather resources, constructs buildings, advances through ages, trains an army, and defeats opponents on a map seen from above.
3. The game is for macOS only, and may use Apple's frameworks freely.
4. A match has two, four or six players. One, two or three of them are human, each at a Mac on the same LAN; the others are computer players.
5. Before a match can start, the players are grouped into teams. All the human players are on one team. The computer players may be grouped in any manner, and a computer player may be placed on the human team.
6. Allies cannot attack one another.
7. A team wins by defeating every player who is not an ally. The match ends then, in whatever age it has reached; a match need not reach the AI age.
8. Each human player has a separate base.
9. The ages follow world history, in this order: Stone, Bronze, Iron, Alchemy, Industrial, Silicon, AI. The Alchemy age covers the medieval and gunpowder periods.
10. Each player in a match has a different civilization, and each civilization bears the name of a historical one. The first version has at least these seven: Sumer, Egypt, Harappa, Shang, Olmec, Caral and Rome. Greece, Angkor, Tonga and Samoa are wanted as well, in the first version or a later one.
11. The game is for personal use. Its source is published in a public repository under AGPL 3.0; no built app is distributed, and the game needs no Developer ID signature and no notarisation. It must still start on every Mac used, without an Apple developer account.
12. The game has several economies, each of which progresses with the ages. Some economies do not start until a certain age.
13. The resources, by the age in which each appears: wood, stone and hunted prey in the Stone age; bronze, gold and herds in the Bronze age; iron and farms in the Iron age; gunpowder in the Alchemy age; oil in the Industrial age; electricity in the Silicon age; data in the AI age. Prey, herds and farms are successive sources of one resource, food.
14. The economies are seven: food, building materials, metal, wealth, chemistry, energy and information. This division is accepted for now and may be revised.
15. A civilization has five sectors, each of which progresses with the ages: workers, warfighters, scholars, engineers and merchants.
16. A player reaches the next age through the work of scholars; an age is not bought with resources alone.
17. When a player reaches a new age, the warfighters already in play remain as they were. The player may pay to upgrade them to the kind the new age brings.
18. Copper and tin are deposits, not resources a player holds. What workers mine from them becomes bronze at once, and bronze is made only whilst the player mines both.
19. A deposit is hidden from a player until that player reaches the age in which its economy starts. It then appears wherever the player has explored. Before then, its explored tiles show as plain rock (an outcrop), which blocks building and movement as the deposit does, without naming what lies there.
20. Each age brings the warfighters and new buildings in the table under "Buildings and ages". The table is accepted for now and may be revised.
21. The drone of the AI age flies. No other unit flies.
22. The computer players have three levels of difficulty: easy, standard and hard.
23. A match can be saved and resumed later.
24. The map is seen at an angle, as in the original: buildings have height and people stand upright. The drawing [`art/view-sample-1.png`](art/view-sample-1.png) shows the view chosen, on its right-hand side.
25. The first version has no ships. Water appears only as terrain that cannot be crossed.
26. A player all of whose people and buildings are destroyed, whilst an ally still lives, receives one person to control: a founder. The founder cannot attack. It can only build one new town centre, which comes with two workers, and it then becomes an engineer (ruled 2026-11-21), so that the player begins again as every player begins. The founder reappears whenever everything the player owns is again destroyed whilst an ally still lives.
27. A founder cannot be killed. A team whose players have only founders is defeated, and the match ends for it.
28. A player may have engineers demolish one of the player's own buildings. Demolition takes half the building's construction time, and when the building comes down the player receives half its cost. Training or research under way there is cancelled and refunded in full. A demolished house lowers the population limit; nobody already living is lost, but no one is trained whilst the population exceeds the limit.
29. A player can speed the match up, and slow it back down to its normal pace.
30. A player may dismiss any of the player's own people, who leave the match at once and free their places in the population; nothing is returned. A founder cannot be dismissed.

## Consequences of the stated requirements

These follow from the requirements above; they are stated so that they can be confirmed or corrected.

- A match needs at least two teams, or no one could be defeated. At least one computer player is therefore not on the human team.
- A match of two players has one human player and one computer player. Three human players need a match of four or six.
- The game is playable by one person alone.
- Up to three Macs take part in one match.

## Constraint: an original work

The game is an original work in the genre. It does not use the name, artwork, sounds, music, text, campaigns or maps of Age of Empires. The mechanics common to the genre are free to use, and so are the names of historical civilizations, which belong to no one.

## Suggested requirements

Each item below is a suggestion, not a ruling. Any of them can be struck, changed or moved out of scope.

### Civilizations

- The civilizations differ in name and colour only; all play by the same rules with the same units and buildings.
- Greece, Angkor, Tonga and Samoa are in the first version, since a further civilization is then a name and a colour and nothing more.
- The civilizations in a match have colours that are easily told apart.
- Each human player chooses a civilization before the match; the computer players take civilizations from those that remain.

### The match

- Each match is played on a newly generated map with open ground, forest, prey, lakes, rivers and coast, deposits of stone, copper, tin, gold and iron, and oil fields.
- Every player, human or computer, begins with a separate base: a town centre, two workers and an engineer (ruled 2026-11-18), so that a house can always be built.
- Ground a player has not explored is hidden; explored ground out of sight of the player's units and buildings shows the terrain but not what opponents are doing there.
- The match's setup offers one setting, "What you see", with three values for the people in the match (ruled 2026-11-20); computer players always explore, whatever the value:
  - "Explore the map" (the default): as above.
  - "Map shown": the whole map's ground and deposits are shown from the start; what is happening is seen only where the player's or an ally's units and buildings see.
  - "Everything in view": the whole map and everything on it, as it is, all the time.
- In a match across the network the host chooses the value, people who join see it in the lobby, and it is saved with the match.
- The founder appears beside an ally's town centre. The town centre it builds costs no resources.
- A player who rebuilds keeps the age reached and the resources held.
- The founder rule applies to every player who has a living ally, computer players included.
- Any human player can pause the match, and the pause holds for all.
- The first human player saves the match under a name, and later opens it; the other human players join as before, and play continues from the moment of saving.
- If a human player is absent when a saved match is resumed, a computer player takes that player's place.
- A match that runs through all seven ages lasts between one hour and one and a half hours. The Stone and Bronze ages pass in a few minutes each.

### Economy

- The table below shows the seven economies. The manner in which each resource is obtained, and the stages after an economy's first, are suggestions.
- Before an economy starts, its resources are not shown to the player and cannot be obtained.
- A player sees only the deposits of the ages that player has reached, whatever an ally can see.
- The map places every kind of deposit within fair reach of every player.
- The direction of progress is from gathering to production. Workers gather wood, stone and food, mine bronze, gold and iron, and carry them to a building that accepts them; the alchemist's workshop makes gunpowder; an oil well pumps oil without workers; power stations and data centres produce electricity and data.
- Each player's start has five copper, five tin and five iron deposits near it, and more are scattered over the field; the map holds as many tin deposits as copper. A copper, tin or iron deposit holds 500.
- Stone and bronze are little needed after the Alchemy age and wood little after the Industrial age, so that a player attends to six or seven resources in any one age. The screen shows only the resources in use in the player's current age.

| Economy | Starts in | Resources | Stages |
|---|---|---|---|
| Food | Stone | Food | Hunted prey (Stone); herds (Bronze); farms (Iron); in later ages a farm yields more |
| Building materials | Stone | Wood, stone | Gathered throughout; little needed in the late ages |
| Metal | Bronze | Bronze, iron | Bronze made from copper and tin, both mined (Bronze); iron mined (Iron) |
| Wealth | Bronze | Gold | Mined |
| Chemistry | Alchemy | Gunpowder | Made in the alchemist's workshop |
| Energy | Industrial | Oil, electricity | Oil pumped by a well on an oil field (Industrial); electricity produced by a power station that consumes oil (Silicon) |
| Information | AI | Data | Produced by a data centre that consumes electricity |

### Sectors

- Every person a player trains belongs to one of the five sectors. The table below shows what each sector does and how it might progress.
- A sector's stage changes with the age. Most stages are the same unit with a new name, a new appearance and better figures; only a few bring new behaviour.
- When a player reaches a new age, the workers, scholars, engineers and merchants already in play change to the new stage at once and without cost.
- Merchants start in the Bronze age, with the Wealth economy. The other four sectors are present from the Stone age.
- In the AI age, robots take the place of workers and warfighters.
- The number of units a player may have is limited, and houses raise the limit up to a fixed maximum.

| Sector | What it does | Stages, from the Stone age to the AI age |
|---|---|---|
| Workers | Gather and produce resources | Hunter, herder, farmer, craftsman, factory hand, technician, robot |
| Warfighters | Fight | See the table under "Buildings and ages" |
| Scholars | Research improvements and bring about the next age | Elder, scribe, philosopher, alchemist, scientist, programmer, researcher |
| Engineers | Construct and repair buildings; operate siege weapons and machines | Builder, mason, siege engineer, gunsmith, mechanic, electronics engineer, roboticist |
| Merchants | Exchange one resource for another; carry resources to an ally | Trader, caravan trader, banker, industrialist, financier, automated exchange |

### Buildings and ages

- A player begins in the Stone age with a town centre and a few workers.
- Buildings include a house, a storage building for gathered resources, a farm, buildings that train each kind of warfighter, a watch tower and walls.
- Scholars at work accumulate progress towards the next age, and more scholars reach it sooner. Advancing also costs a modest amount of resources.
- A new age makes further buildings, units and improvements available.
- Scholars research improvements at buildings, for example better tools for workers and better weapons and armour for warfighters.
- Each age brings the warfighters and buildings below. A warfighter of an earlier age can still be trained in a later one, but is weak against the warfighters of that later age.

| Age | Warfighters | New buildings |
|---|---|---|
| Stone | Clubman, slinger | Town centre, house, storage pit |
| Bronze | Spearman, archer, chariot | Stock pen, barracks, watch tower, palisade |
| Iron | Swordsman, horseman, catapult | Farm, stable, siege workshop, stone wall |
| Alchemy | Knight, musketeer, cannon | Castle, alchemist's workshop |
| Industrial | Rifleman, field gun, armoured car | Factory, railway depot, oil well |
| Silicon | Mechanised infantry, tank, missile launcher | Laboratory, power station |
| AI | Combat robot, autonomous tank, drone | Data centre |

### Military

- Each age has its own military units, in keeping with its period.
- Unit types have strengths and weaknesses against one another, so that the composition of an army matters.
- Towers and the town centre shoot at opponents within range.
- A weapon that damages an area does no harm to an ally's units and buildings.
- The drone crosses forest and passes over walls. Only warfighters and buildings that shoot can attack it.

### Controls

- Units are selected by a click or by dragging a box, and ordered by a click on the ground, a resource, a building or an opponent.
- Selected units can be assigned to numbered groups and recalled by number.
- A small map of the whole field shows explored ground, the player's and the allies' units, and visible opponents; a click on it moves the view.
- Buildings and units are chosen from a panel, and the common actions have keyboard shortcuts.

### Co-operative play

- A player sees everything any ally sees.
- A player's merchants carry resources to an ally.
- A further human player joins the first human player's match without typing a network address.
- The game needs no internet connection, no account and no separate server.

### The computer players

- A computer player gathers, builds, advances through the ages and sends armies, by the same rules as the human players.
- Computer players on one team act together.
- A level of difficulty governs how well a computer player plays, not what it is given: at every level it plays by the same rules as a human player and receives no extra resources.
- The level is set for each computer player separately, where the teams are grouped before the match.

### Presentation

- Artwork is simple and legible: every unit type, building type and resource is distinguishable at a glance.
- There are basic sound effects for orders, combat and completed buildings. Music is not required.
- The game stays smooth with two hundred units for each player on the Macs in use.

## Suggested as out of scope

- Play over the internet.
- More than three human players, and human players as opponents of one another.
- Matches of three or five players.
- Civilizations that differ in their units, buildings or rules.
- Ships and water combat.
- A campaign, scripted scenarios, or a map editor.
- Code signing and notarisation.

## Facts

- Every Mac that will run the game is Apple silicon (stated 2026-11-18). The Mac on which the game is developed runs macOS 26.
- A web search on 2026-11-18 found no game titled "Cities of Progress". The nearest title found is "Times of Progress", a city-building game.

## Open questions

These are questions about what the game must do, not how.

None at present.
