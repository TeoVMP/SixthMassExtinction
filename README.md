# SIXTH MASS EXTINCTION: TEMPORAL INSURGENCY

## THE DUAL PROJECT: TWO GAMES, ONE REVOLUTION

Sixth Mass Extinction is a franchise of two complementary games exploring the same epic narrative from radically different gameplay perspectives:

**SIXTH MASS EXTINCTION: TEMPORAL STRATEGY** (IN DEVELOPMENT)
A geopolitical strategy and management game where every decision affects humanity's fate. Control resources, reputation, and sanity while facing the oligarchy orchestrating climate collapse.

**SIXTH MASS EXTINCTION: SURVIVAL AGAINST COLLAPSE** (PLANNED)
A first-person survival shooter where you experience the revolution on the ground. Protect ecosystems, infiltrate corporate facilities, and fight for survival as the world crumbles.

---

## SIXTH MASS EXTINCTION: TEMPORAL STRATEGY

### THE YEAR IS 2055. THE WORLD IS CRUMBLING. YOU HAVE A TIME MACHINE.

You are Alexei Volkov, a scientist from a collapsed future who travels to 2028 to prevent the Sixth Mass Extinction. Every decision rewrites reality, every alliance shifts geopolitical balance, and every manifesto you write can ignite—or extinguish—revolutions.

---

## CORE GAMEPLAY SYSTEMS

### SANITY MANAGEMENT (0-100)

Your mental health is your most valuable and fragile resource. As a scientist raised in laboratories, every act of violence, every necessary lie, every life taken erodes your sanity.

**SANITY LEVELS:**
- **> 70** : Strategic clarity (+15% diplomacy)
- **50-70** : Precarious stability
- **30-50** : Operative depression (-10% all abilities)
- **15-30** : Existential crisis (risk of impulsive decisions)
- **< 15** : Psychological abyss (1%/day suicide risk)

**Affecting Factors:**
- Killing humans: -20 (first time), -10 (subsequent)
- Killing animals: -15
- Seeing children/allies die: -25
- Non-violent victory: +10
- Saving innocent lives: +5

### GLOBAL REPUTATION SYSTEM

Seven geopolitical regions judge you differently. What gains allies in the Global South may lose support in Europe.

**REGIONAL REPUTATION (BASE):**
- Africa: +40
- Latin America: +45
- South Asia: +30
- China: +10
- Western Europe: 0
- Russia: -10
- North America: -20

**Impact Formula:**
```
Impact = (Base × Moral Multiplier) × Propaganda Factor
```

**Moral Multipliers:**
- Anonymous action: ×0.5
- With effective manifesto: ×1.5
- With irrefutable proof: ×2.0
- Human collateral damage: ×0.3
- Ecological collateral: ×0.1

### DYNAMIC GLOBAL VIOLENCE

Your actions—and your enemies'—create a global violence index affecting all operations.

```
GLOBAL VIOLENCE = 
  40% Active Conflicts (wars, coups)
  30% State Repression (violent protests, censorship)
  20% Organized Crime (drug trafficking, militias)
  10% Ecoviolence (ecocide, environmental sabotage)
```

**High Violence Effects (>70):**
- -25% diplomatic effectiveness
- +40% cost of peaceful operations
- +30% recruitment for violent factions
- Unlocks "Violence Spiral" events

### AI-POWERED MANIFESTO ENGINE

After major operations, you draft revolutionary manifestos. Our AI system analyzes your text and generates realistic responses from governments, media, and populations.

**Real-time Analysis:**
- Coherence: Do your words match your actions?
- Radicalism: Call for reform or revolution?
- Evidence: Base arguments on concrete proof?
- Empathy: Connect with specific cultures?

**Generated Responses From:**
- Media outlets (The Guardian, Al Jazeera, Xinhua)
- Governments and international organizations
- Activists and local communities
- The Cartographers (your antagonists)

### DUAL PUZZLE SYSTEM

Two modes based on difficulty:

**NORMAL (Pure Logic):**
- Climate patterns to complete
- Logical deductions about ecological consequences
- Sequences of revolutionary symbols
- For players preferring pure strategy

**HACKER (Real Cybersecurity):**
- Exploitation of known CVE's
- Web vulnerabilities (basic SQLi, XSS)
- Network capture forensic analysis
- Basic cryptography (classical ciphers)
- Simplified social engineering
- Based on real introductory-level challenges

---

## THE STORY: 36 MISSIONS + 2 BONUS

### ACT I: THE FOUNDATIONS (2028-2030)

From Iceland to the Amazon, you establish your global presence while discovering the collapse isn't accidental—it's orchestrated.

**Key Missions:**
- Refuge in the Ice - Find the Prometheus Circle
- Orphans of the Thaw - Save Andean glaciers
- The Amazon's Heartbeat - Protect uncontacted tribes
- The 2030 Harvest - Disrupt mass resource acquisition

### ACT II: TEMPORAL COLD WAR (2031-2033)

You discover temporal agents, confront dangerous geoengineering, and infiltrate the Cartographers' University.

**Key Missions:**
- 13. The Dividing Canal - Stop Central American megaproject
- 18. The Romanian Coup - Prevent ecofascist dictatorship
- 23. The Trial of the Century - Sue oil companies in The Hague

### ACT III: FINAL CONFLICT (2034-2035)

The final battle for humanity's future. Four possible endings based on your accumulated choices.

**Key Missions:**
- 31. The Ark Refuge - Infiltrate the Cartographers' bunker
- 34. The Abyss Summit - Final UN vote
- 36. The Sixth Choice - Your legacy determines the future

---

## TECHNICAL ARCHITECTURE

### TECH STACK

**FRONTEND (Interface):**
- **Godot Engine 4.2+** (GDScript)
- UI/UX rendering and visual systems
- Puzzle system interface
- Manifesto editor
- Maps and animations

**BACKEND (Simulation):**
- **Go 1.25.5+** (Complex systems)
- Sanity/reputation simulation
- Complex geopolitical calculations
- Game state management
- JSON-RPC server implementation

**COMMUNICATION:**
- **JSON-RPC** over HTTP/WebSocket
- RESTful API for VPN and mission management

**CONTAINERIZATION & VIRTUALIZATION:**
- **Rancher Desktop** - Primary container runtime (replaces Docker Desktop)
- **nerdctl** - CLI tool for managing containers via containerd
- **Docker/containerd** - Container runtime backend
- **VMware Workstation/Player** - For running penetration testing VMs
- **Parrot OS / Kali Linux** - Linux distributions for external VM attacks

**NETWORKING & VPN:**
- **WireGuard** - Modern VPN protocol for secure mission network access
- **linuxserver/wireguard** - Containerized WireGuard server
- **Docker Bridge Networks** - Isolated network for mission containers (10.10.0.0/24)
- **NAT Mode** - For VMware VMs connecting to the game network

**PENETRATION TESTING TOOLS:**
All tools are pre-installed in Kali Linux containers:
- **Network Tools**: nmap, netcat, socat, whatweb, curl, wget
- **Exploitation Frameworks**: Metasploit Framework, Marshalsec (for Log4Shell)
- **Analysis Tools**: Wireshark, Aircrack-ng, Hydra, SQLMap
- **Development Tools**: Java JDK 11, Maven, Python 3, Git
- **Custom Exploit Scripts** - Pre-compiled exploits for specific vulnerabilities

**AI & MACHINE LEARNING:**
- **Ollama** - Local LLM runtime (optional)
- **phi3:mini** (3.8GB) - Recommended model for manifesto analysis
- **Alternative Models**: gemma:2b, llama3.2:1b, mistral:7b
- Fallback to simulated analysis if Ollama unavailable

**DATABASE:**
- **SQLite** (local)
- **PostgreSQL** (cloud optional)

**DEVELOPMENT TOOLS:**
- **PowerShell** (Windows) - Automation and scripting
- **Bash/Shell** (Linux/Mac) - Unix shell scripting
- **Git** - Version control
- **GitHub** - Remote repository hosting

### RESPONSIBILITY DIVISION

```go
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
- Container orchestration (Docker/nerdctl)
- VPN server management (WireGuard)
- Mission network isolation
- Terminal container lifecycle
```

### DATA FLOW

```
Godot → JSON Action → Go Backend → Simulation → JSON Result → Godot
        (Player acts)    (Calculates consequences)   (Updates interface)
```

### MISSION NETWORK ARCHITECTURE

```
VMware VM (Parrot OS/Kali Linux)
  └─ WireGuard VPN Client (10.10.0.10/24)
         │
         │ WireGuard VPN Tunnel
         │
Host (Windows/Linux/Mac)
  └─ Docker Network: sme-mission-network (10.10.0.0/24)
         │
         ├─ WireGuard Server Container (10.10.0.2)
         │   └─ Routes traffic between VPN and Docker network
         │
         ├─ Terminal Containers (Kali Linux)
         │   └─ Pre-installed penetration testing tools
         │
         └─ Victim Server Containers (10.10.0.100+)
             └─ Vulnerable services for hacking missions
```

---

## MULTIPLE ENDINGS

### ENDING A: THE PEACEFUL REVOLUTION
**Requires:** Reputation > 800, Sanity > 70, Minimal violence

The world adopts Climate Democracy through global consensus. You retire, your past self grows in a healed world.

### ENDING B: THE VICTORIOUS INSURGENCY
**Requires:** Military allies > civilian, Polarized reputation

You take power "temporarily" to dismantle the old system. The screen fades with the question: "Power corrupts. Will you be different?"

### ENDING C: THE NECESSARY SACRIFICE
**Requires:** Ethically questionable decisions

You saved the planet but lost your soul. The Cartographers were defeated, but their methods endure. You rule from the shadows.

### ENDING D: THE NEW BEGINNING
**Requires:** Saved your past self, Built alternatives

You don't take power. Instead, you help build "The Network"—a parallel society that will replace the old system when it collapses.

---

## COMMUNITY DEVELOPMENT & OPEN SOURCE

### PHILOSOPHY

This game is more than entertainment—it's a collective thought experiment about the ethical limits of climate activism. We build it openly because the questions we ask belong to everyone.

### HOW TO CONTRIBUTE

- **Programmers**: Simulation systems in Go, Godot integration, container orchestration
- **Ecologists**: Accurate climate modeling, ecosystem data
- **Linguists**: Discourse analysis, culturally sensitive translations
- **Game Designers**: Mechanics balancing, puzzle design
- **Artists**: 2D/3D assets, interface design
- **Writers**: Branching narrative, dialogues
- **Security Researchers**: Realistic vulnerability scenarios, exploit development

### REPOSITORY STRUCTURE

```
sixth-mass-extinction/
├── strategy/                  # Strategy game (current)
│   ├── godot_frontend/       # Godot interface
│   ├── go_backend/           # Go simulation
│   │   ├── handlers/         # Request handlers
│   │   │   ├── docker_client.go    # Docker/nerdctl abstraction
│   │   │   ├── network.go          # Network management
│   │   │   ├── vpn.go              # VPN server implementation
│   │   │   ├── terminal.go         # Terminal container management
│   │   │   └── victim_os.go        # Victim server containers
│   │   └── main.go           # Server entry point
│   ├── docker/               # Docker configuration
│   │   ├── Dockerfile.kali-6me # Custom Kali Linux image
│   │   └── build scripts     # Image build automation
│   └── shared_protocols/     # Communication
├── survival/                 # FPS shooter (future)
├── docs/
│   ├── MISSION0_WRITEUP.md   # Mission 0 complete guide
│   ├── TERMINAL_SYSTEM_DOCUMENTATION.md
│   └── ARCHITECTURE.md       # Technical specifications
└── community_assets/         # Open contributions
```

### LICENSES

- **Code**: GNU GPL v3.0
- **Art assets**: CC BY-SA 4.0
- **Narrative content**: Collective Commons Attribution
- **Scientific data**: Cite original sources

---

## CURRENT STATUS & ROADMAP

### PHASE 1: CORE PROTOTYPE ✅ (COMPLETED)

- ✅ Complete systems and narrative design
- ✅ Sanity/reputation implementation in Go
- ✅ Basic UI in Godot
- ✅ First playable mission (Iceland/NSA Breach)
- ✅ Docker containerization system
- ✅ WireGuard VPN integration
- ✅ Terminal system with Kali Linux containers
- ✅ Real penetration testing tools integration
- ✅ Mission network isolation

### PHASE 2: STRATEGY MVP (IN PROGRESS)

- 🔄 12 complete Act I missions
- 🔄 8 functional geopolitical regions
- ✅ Basic manifesto AI (Ollama integration)
- ✅ Logical puzzle system
- ✅ Hacker puzzle system (real CVE exploitation)
- 🔄 Network connectivity fixes (VMware NAT mode)

### PHASE 3: COMPLETE GAME (Q4 2024)

- ⏳ 38 complete missions
- ⏳ Global violence system
- ⏳ Four implemented endings
- ⏳ Complete localization

### PHASE 4: HACKER CONTENT (Q1 2025)

- ⏳ Real cybersecurity puzzles
- ⏳ Hacker bonus missions
- ⏳ "Reality Source Code" mode

---

## SIXTH MASS EXTINCTION: SURVIVAL AGAINST COLLAPSE (PREVIEW)

### CONCEPT

Same universe, different perspective. An FPS survival game where you experience the revolution on the ground. Protect endangered species at gunpoint, hack corporate drones in real-time, and survive in collapsing ecosystems.

### PLANNED MECHANICS

- Device possession: Take control of drones, cameras, systems
- Ecological survival: Resource management in degraded biomes
- Tactical combat: Confrontations against corporate forces
- NPC relationships: Build alliances, find a partner in the struggle

### STRATEGY INTEGRATION

- Save games compatible between games
- Strategy decisions affect Survival world
- Synchronized global events

---

## QUICK START

### Prerequisites

1. **Install Rancher Desktop** or Docker Desktop
   - Download from [rancherdesktop.io](https://rancherdesktop.io/)
   
2. **Install Go 1.25.5+**
   - Download from [golang.org/dl](https://golang.org/dl/)

3. **Install Godot Engine 4.2+**
   - Download from [godotengine.org](https://godotengine.org/download)

4. **Optional: Install Ollama** (for AI manifesto analysis)
   - Download from [ollama.com](https://ollama.com/download)
   - Run: `ollama pull phi3:mini`

5. **Optional: Install VMware** (for external VM attacks)
   - Download VMware Workstation/Player
   - Install Parrot OS or Kali Linux as VM

### Setup

```bash
# Clone the repository
git clone https://github.com/TeoVMP/SixthMassExtinction.git
cd SixthMassExtinction/strategy

# Build custom Kali image (optional but recommended)
cd docker
# Windows:
.\build-kali-image.bat
# Linux/Mac:
chmod +x build-kali-image.sh && ./build-kali-image.sh

# Start the backend
cd ../go_backend
go run main.go

# Open Godot and import the project from godot_frontend/
```

### First Mission

1. Start the game in Godot
2. Select Mission 0: "NSA Breach"
3. Connect to VPN from your VM (if using external VM)
4. Use real penetration testing tools to exploit Log4Shell (CVE-2021-44228)
5. Complete objectives and see your impact on the world

---

## JOIN THE REVOLUTION

This isn't just game development. It's preparation.

**Start by:**
- Read `docs/` for collaboration guidelines
- Explore `strategy/go_backend/` if you know Go
- Check `strategy/godot_frontend/` if you know Godot
- Review `docker/` for container setup
- Join the discussion in Issues

**Project Lead:** Teo Valentin Marpegan (GitHub: @TeoVMP)

---

> "The world is ending. Again. But this time, we have a time machine and nothing left to lose."

---

## KNOWN ISSUES

See [ISSUE_VPN_VMWARE_CONNECTIVITY.md](ISSUE_VPN_VMWARE_CONNECTIVITY.md) for current VPN connectivity issues with VMware NAT mode.

---

**Note**: This game involves real penetration testing tools and techniques. Use responsibly and only in authorized environments.
