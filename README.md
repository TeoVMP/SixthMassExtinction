SIXTH MASS EXTINCTION: TEMPORAL INSURGENCY
THE DUAL PROJECT: TWO GAMES, ONE REVOLUTION
Sixth Mass Extinction is a franchise of two complementary games exploring the same epic narrative from radically different gameplay perspectives:

SIXTH MASS EXTINCTION: TEMPORAL STRATEGY (IN DEVELOPMENT)
A geopolitical strategy and management game where every decision affects humanity's fate. Control resources, reputation, and sanity while facing the oligarchy orchestrating climate collapse.

SIXTH MASS EXTINCTION: SURVIVAL AGAINST COLLAPSE (PLANNED)
A first-person survival shooter where you experience the revolution on the ground. Protect ecosystems, infiltrate corporate facilities, and fight for survival as the world crumbles.

SIXTH MASS EXTINCTION: TEMPORAL STRATEGY
THE YEAR IS 2055. THE WORLD IS CRUMBLING. YOU HAVE A TIME MACHINE.
You are Alexei Volkov, a scientist from a collapsed future who travels to 2028 to prevent the Sixth Mass Extinction. Every decision rewrites reality, every alliance shifts geopolitical balance, and every manifesto you write can ignite—or extinguish—revolutions.

CORE GAMEPLAY SYSTEMS
SANITY MANAGEMENT (0-100)
Your mental health is your most valuable and fragile resource. As a vegan scientist raised in laboratories, every act of violence, every necessary lie, every life taken erodes your sanity.

text
SANITY LEVELS:
> 70  : Strategic clarity (+15% diplomacy)
50-70 : Precarious stability
30-50 : Operative depression (-10% all abilities)
15-30 : Existential crisis (risk of impulsive decisions)
< 15  : Psychological abyss (1%/day suicide risk)
Affecting Factors:

Killing humans: -20 (first time), -10 (subsequent)

Killing animals: -15 (if vegan)

Seeing children/allies die: -25

Non-violent victory: +10

Saving innocent lives: +5

GLOBAL REPUTATION SYSTEM
Eight geopolitical regions judge you differently. What gains allies in the Global South may lose support in Europe.

text
REGIONAL REPUTATION (BASE):
Exploited Peoples       : +50  (Africa, Indigenous Latin America, Southeast Asia)
United Africa           : +40
Latin America           : +45  
South Asia              : +30
China                   : +10
Western Europe          : 0
Russia                  : -10
North America           : -20
Impact Formula:

math
Impact = (Base × Moral Multiplier) × Propaganda Factor

Moral Multipliers:
Anonymous action        : ×0.5
With effective manifesto: ×1.5
With irrefutable proof  : ×2.0
Human collateral damage : ×0.3
Ecological collateral   : ×0.1
DYNAMIC GLOBAL VIOLENCE
Your actions—and your enemies'—create a global violence index affecting all operations.

text
GLOBAL VIOLENCE = 
  40% Active Conflicts (wars, coups)
  30% State Repression (violent protests, censorship)
  20% Organized Crime (drug trafficking, militias)
  10% Ecoviolence (ecocide, environmental sabotage)
High Violence Effects (>70):

-25% diplomatic effectiveness

+40% cost of peaceful operations

+30% recruitment for violent factions

Unlocks "Violence Spiral" events

AI-POWERED MANIFESTO ENGINE
After major operations, you draft revolutionary manifestos. Our AI system analyzes your text and generates realistic responses from governments, media, and populations.

Real-time Analysis:

Coherence: Do your words match your actions?

Radicalism: Call for reform or revolution?

Evidence: Base arguments on concrete proof?

Empathy: Connect with specific cultures?

Generated Responses From:

Media outlets (The Guardian, Al Jazeera, Xinhua)

Governments and international organizations

Activists and local communities

The Cartographers (your antagonists)

DUAL PUZZLE SYSTEM
Two modes based on difficulty:

NORMAL (Pure Logic):
Climate patterns to complete

Logical deductions about ecological consequences

Sequences of revolutionary symbols

For players preferring pure strategy

HACKER (Real Cybersecurity):
Web vulnerabilities (basic SQLi, XSS)

Network capture forensic analysis

Basic cryptography (classical ciphers)

Simplified social engineering

Based on real introductory-level challenges

THE STORY: 36 MISSIONS + 2 BONUS
ACT I: THE FOUNDATIONS (2028-2030)
From Iceland to the Amazon, you establish your global presence while discovering the collapse isn't accidental—it's orchestrated.

Key Missions:

Refuge in the Ice - Find the Prometheus Circle

Orphans of the Thaw - Save Andean glaciers

The Amazon's Heartbeat - Protect uncontacted tribes

The 2030 Harvest - Disrupt mass resource acquisition

ACT II: TEMPORAL COLD WAR (2031-2033)
You discover temporal agents, confront dangerous geoengineering, and infiltrate the Cartographers' University.

Key Missions:
13. The Dividing Canal - Stop Central American megaproject
18. The Romanian Coup - Prevent ecofascist dictatorship
23. The Trial of the Century - Sue oil companies in The Hague

ACT III: FINAL CONFLICT (2034-2035)
The final battle for humanity's future. Four possible endings based on your accumulated choices.

Key Missions:
31. The Ark Refuge - Infiltrate the Cartographers' bunker
34. The Abyss Summit - Final UN vote
36. The Sixth Choice - Your legacy determines the future

TECHNICAL ARCHITECTURE
TECH STACK
text
FRONTEND (Interface) : Godot Engine 4.2+ (GDScript)
BACKEND (Simulation) : Go 1.21+ (Complex systems)
COMMUNICATION        : JSON-RPC over WebSocket
DATABASE             : SQLite (local), PostgreSQL (cloud optional)
MANIFESTO AI         : Local models (small transformers)
RESPONSIBILITY DIVISION
go
// Godot handles:
- UI/UX and rendering
- Visual puzzle system
- Manifesto editor
- Maps and animations

// Go handles:
- Sanity/reputation simulation
- Text analysis AI
- Complex geopolitical calculations
- Game state management
DATA FLOW
text
Godot → JSON Action → Go Backend → Simulation → JSON Result → Godot
        (Player acts)    (Calculates consequences)   (Updates interface)
MULTIPLE ENDINGS
ENDING A: THE PEACEFUL REVOLUTION
Requires: Reputation > 800, Sanity > 70, Minimal violence
The world adopts Climate Democracy through global consensus. You retire, your past self grows in a healed world.

ENDING B: THE VICTORIOUS INSURGENCY
Requires: Military allies > civilian, Polarized reputation
You take power "temporarily" to dismantle the old system. The screen fades with the question: "Power corrupts. Will you be different?"

ENDING C: THE NECESSARY SACRIFICE
Requires: Ethically questionable decisions
You saved the planet but lost your soul. The Cartographers were defeated, but their methods endure. You rule from the shadows.

ENDING D: THE NEW BEGINNING
Requires: Saved your past self, Built alternatives
You don't take power. Instead, you help build "The Network"—a parallel society that will replace the old system when it collapses.

COMMUNITY DEVELOPMENT & OPEN SOURCE
PHILOSOPHY
This game is more than entertainment—it's a collective thought experiment about the ethical limits of climate activism. We build it openly because the questions we ask belong to everyone.

HOW TO CONTRIBUTE
Programmers: Simulation systems in Go, Godot integration

Ecologists: Accurate climate modeling, ecosystem data

Linguists: Discourse analysis, culturally sensitive translations

Game Designers: Mechanics balancing, puzzle design

Artists: 2D/3D assets, interface design

Writers: Branching narrative, dialogues

REPOSITORY STRUCTURE
text
sixth-mass-extinction/
├── strategy/                  # Strategy game (current)
│   ├── godot_frontend/       # Godot interface
│   ├── go_backend/           # Go simulation
│   └── shared_protocols/     # Communication
├── survival/                 # FPS shooter (future)
├── docs/
│   ├── GDD_STRATEGY.md       # Complete design document
│   └── ARCHITECTURE.md       # Technical specifications
└── community_assets/         # Open contributions
LICENSES
Code: GNU GPL v3.0

Art assets: CC BY-SA 4.0

Narrative content: Collective Commons Attribution

Scientific data: Cite original sources

CURRENT STATUS & ROADMAP
PHASE 1: CORE PROTOTYPE (IN PROGRESS)
Complete systems and narrative design

Sanity/reputation implementation in Go

Basic UI in Godot

First playable mission (Iceland)

ETA: 2-3 weeks

PHASE 2: STRATEGY MVP (Q2 2024)
12 complete Act I missions

8 functional geopolitical regions

Basic manifesto AI

Logical puzzle system

PHASE 3: COMPLETE GAME (Q4 2024)
38 complete missions

Global violence system

Four implemented endings

Complete localization

PHASE 4: HACKER CONTENT (Q1 2025)
Real cybersecurity puzzles

Hacker bonus missions

"Reality Source Code" mode

SIXTH MASS EXTINCTION: SURVIVAL AGAINST COLLAPSE (PREVIEW)
CONCEPT
Same universe, different perspective. An FPS survival game where you experience the revolution on the ground. Protect endangered species at gunpoint, hack corporate drones in real-time, and survive in collapsing ecosystems.

PLANNED MECHANICS
Device possession: Take control of drones, cameras, systems

Ecological survival: Resource management in degraded biomes

Tactical combat: Confrontations against corporate forces

NPC relationships: Build alliances, find a partner in the struggle

STRATEGY INTEGRATION
Save games compatible between games

Strategy decisions affect Survival world

Synchronized global events

JOIN THE REVOLUTION
This isn't just game development. It's preparation.

Start by:

Read docs/CONTRIBUTING.md for collaboration guidelines

Explore strategy/go_backend/ if you know Go

Check strategy/godot_frontend/ if you know Godot

Join the discussion in Issues

Project Lead: Teo Valentin Marpegan (GitHub: @TeoVMP)

"The world is ending. Again. But this time, we have a time machine and nothing left to lose."
