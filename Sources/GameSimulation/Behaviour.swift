// SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
// SPDX-License-Identifier: AGPL-3.0-or-later

import GameCore

// What people and buildings do in a tick.

extension Simulation {
    mutating func updatePerson(_ i: Int) {
        if entities[i].cooldown > 0 { entities[i].cooldown -= 1 }
        if let pending = entities[i].upgrade {
            if pending.remaining <= 1 { finishUpgrade(i, to: pending.to) } else { entities[i].upgrade?.remaining -= 1 }
        }
        switch entities[i].task {
        case .idle: entities[i].doing = .idle
        case .move(let point): moveTask(i, to: point)
        case .gather(let site, let kind, let tile): gatherTask(i, site: site, kind: kind, tile: tile)
        case .work(let building): workTask(i, at: building)
        case .attack(let target): attackTask(i, target: target)
        }
    }

    mutating func setIdle(_ i: Int) {
        entities[i].task = .idle
        entities[i].doing = .idle
        entities[i].route = Route()
    }

    /// Give a person a new task, forgetting its route.
    mutating func assign(_ i: Int, _ task: Task) {
        entities[i].task = task
        entities[i].route = Route()
        entities[i].dropOff = nil
    }

    // MARK: Moving

    mutating func moveTask(_ i: Int, to point: MapPosition) {
        switch approach(i, .point(point, reach: Rule.pointReach)) {
        case .arrived, .unreachable: setIdle(i)
        case .moving: entities[i].doing = .moving
        }
    }

    // MARK: Gathering

    /// Units of a site's yield a worker takes per tick.
    func gatheringRate(_ kind: SiteKind, player: Int) -> Double {
        let tools = players[player].has(.betterTools) ? ImprovementEffect.betterToolsGathering : 1
        return catalogue.gathering.perSecond(kind) * tools / Double(Tick.rate)
    }

    mutating func gatherTask(_ i: Int, site: SiteID, kind: SiteKind, tile: GridPoint) {
        let owner = entities[i].owner.rawValue
        let load = catalogue.gathering.load
        var siteIndex = self.siteIndex(of: site)
        if siteIndex == nil, let next = nearestSite(kind, near: tile, team: players[owner].teamIndex) {
            // The site is exhausted: the worker turns to the nearest other of its kind.
            entities[i].task = .gather(site: sites[next].id, kind: kind, tile: sites[next].tile)
            entities[i].route = Route()
            siteIndex = next
        }
        let carried = entities[i].cargo?.amount ?? 0
        if carried >= load || (siteIndex == nil && carried > 0) {
            carryHome(i, kind: kind, thenIdle: siteIndex == nil)
            return
        }
        guard let s = siteIndex else { setIdle(i); return }
        let target = sites[s]
        switch approach(i, .tiles(target.tile, GridPoint(1, 1), reach: Rule.besideReach)) {
        case .moving: entities[i].doing = .moving; return
        case .unreachable: setIdle(i); return
        case .arrived: break
        }
        entities[i].doing = .gathering
        face(i, dx: target.tile.centre.x - entities[i].position.x, dy: target.tile.centre.y - entities[i].position.y)
        var fraction = entities[i].fraction + gatheringRate(kind, player: owner)
        var amount = carried, remaining = target.remaining
        while fraction >= 1 && amount < load && remaining > 0 {
            fraction -= 1
            amount += 1
            remaining -= 1
        }
        entities[i].fraction = amount >= load ? 0 : fraction
        entities[i].cargo = Cargo(kind: kind, amount: amount)
        if remaining != target.remaining {
            sites[s].remaining = remaining
            if remaining == 0 { exhaust(s) }
        }
    }

    /// Walk a load to the nearest own building that accepts it, and deliver it.
    mutating func carryHome(_ i: Int, kind: SiteKind, thenIdle: Bool) {
        entities[i].doing = .carrying
        var drop = entities[i].dropOff.flatMap { index(of: $0) }
        if let d = drop, !accepts(d, kind.yield, from: entities[i].owner) { drop = nil }
        if drop == nil {
            drop = nearestDropOff(for: i, accepting: kind.yield)
            entities[i].dropOff = drop.map { entities[$0].id }
            entities[i].route = Route()
        }
        guard let d = drop else { return }
        switch approach(i, .tiles(entities[d].origin, entities[d].size, reach: Rule.besideReach)) {
        case .moving: return
        case .unreachable: setIdle(i); return
        case .arrived: break
        }
        deliver(i)
        if thenIdle {
            setIdle(i)
        } else {
            entities[i].route = Route()
            entities[i].doing = .moving
        }
    }

    func accepts(_ building: Int, _ resource: Resource, from owner: PlayerID) -> Bool {
        let e = entities[building]
        guard e.alive, e.complete, e.owner == owner, let kind = e.buildingKind else { return false }
        return tables.building(kind).accepts.contains(resource)
    }

    /// The nearest complete own building that accepts a resource; ties go to the lower id.
    func nearestDropOff(for i: Int, accepting resource: Resource) -> Int? {
        let owner = entities[i].owner, position = entities[i].position
        var best: Int?
        var bestDistance = Double.infinity
        for j in entities.indices where !entities[j].isPerson && accepts(j, resource, from: owner) {
            let d = Goal.tiles(entities[j].origin, entities[j].size, reach: 0).distance(to: position)
            if d < bestDistance { best = j; bestDistance = d }
        }
        return best
    }

    /// The nearest site of a kind with something left, near where the last one was,
    /// on a tile the team has explored.
    func nearestSite(_ kind: SiteKind, near tile: GridPoint, team: Int) -> Int? {
        var best: Int?
        var bestDistance = Double.infinity
        for s in sites.indices where sites[s].kind == kind && sites[s].remaining > 0 && isExplored(sites[s].tile, by: team) {
            let d = sites[s].tile.centre.distance(to: tile.centre)
            if d <= Rule.resiteRadius && d < bestDistance { best = s; bestDistance = d }
        }
        return best
    }

    /// Credit a worker's load to its owner. Copper and tin ore pair into bronze,
    /// one unit of each to one of bronze; unpaired ore is held up to one load of
    /// each, and the rest is lost (`Order.gather`).
    mutating func deliver(_ i: Int) {
        guard let cargo = entities[i].cargo else { return }
        let p = entities[i].owner.rawValue
        let load = catalogue.gathering.load
        switch cargo.kind {
        case .copper, .tin:
            if cargo.kind == .copper { players[p].copperOre += cargo.amount } else { players[p].tinOre += cargo.amount }
            let pairs = min(players[p].copperOre, players[p].tinOre)
            players[p].resources[.bronze] += pairs
            players[p].copperOre = min(players[p].copperOre - pairs, load)
            players[p].tinOre = min(players[p].tinOre - pairs, load)
        default:
            players[p].resources[cargo.kind.yield] += cargo.amount
        }
        entities[i].cargo = nil
        entities[i].dropOff = nil
    }

    /// A site has run out: it vanishes from views and no longer blocks its tile.
    mutating func exhaust(_ s: Int) {
        let t = sites[s].tile
        guard inMap(t), siteAt[tileIndex(t)] == Int32(s) else { return }
        siteAt[tileIndex(t)] = -1
        blocked[tileIndex(t)] = !terrain[tileIndex(t)].isPassable || buildingAt[tileIndex(t)] >= 0
    }

    // MARK: Working at a building

    /// Workers tend a stock pen; engineers construct or repair; scholars research
    /// what is under way there or, at a town centre, study toward the next age.
    mutating func workTask(_ i: Int, at building: EntityID) {
        guard let b = index(of: building), entities[b].owner == entities[i].owner,
              let buildingKind = entities[b].buildingKind, let kind = entities[i].unitKind,
              hasWork(kind, at: b) else { setIdle(i); return }
        switch approach(i, .tiles(entities[b].origin, entities[b].size, reach: Rule.besideReach)) {
        case .moving: entities[i].doing = .moving; return
        case .unreachable: setIdle(i); return
        case .arrived: break
        }
        face(i, dx: entities[b].position.x - entities[i].position.x, dy: entities[b].position.y - entities[i].position.y)
        let p = entities[i].owner.rawValue
        let stats = tables.building(buildingKind)
        switch kind {
        case .worker:
            entities[i].doing = .working
            let earned = entities[i].fraction + catalogue.gathering.herdingPerSecond / Double(Tick.rate)
            let whole = Int(earned.rounded(.down))
            entities[i].fraction = earned - Double(whole)
            players[p].resources[.food] += whole
        case .engineer:
            let buildTime = max(1, stats.buildTime)
            if !entities[b].complete {
                entities[i].doing = .constructing
                entities[b].built += 1
                credit(b, health: stats.health, per: buildTime)
                if entities[b].built >= buildTime { complete(b) }
            } else {
                entities[i].doing = .working
                credit(b, health: stats.health, per: buildTime)
                if entities[b].health >= entities[b].maxHealth { entities[b].healthCredit = 0 }
            }
        case .scholar:
            entities[i].doing = .working
            if let research = entities[b].research {
                entities[b].researchProgress += 1
                if entities[b].researchProgress >= catalogue.stats(research).work { finishResearch(b) }
            } else if buildingKind == .townCentre, let advance = catalogue.advance(from: players[p].age),
                      players[p].age.next != nil {
                players[p].study = min(advance.study, players[p].study + 1)
            }
        default:
            setIdle(i)
        }
    }

    /// Whether a person of this kind has anything to do at a building.
    func hasWork(_ kind: UnitKind, at b: Int) -> Bool {
        let e = entities[b]
        guard let buildingKind = e.buildingKind else { return false }
        switch kind {
        case .worker: return e.complete && buildingKind == .stockPen
        case .engineer: return !e.complete || e.health < e.maxHealth
        case .scholar: return e.complete && (buildingKind == .townCentre || !tables.building(buildingKind).researches.isEmpty)
        default: return false
        }
    }

    /// Construction and repair restore a building's health at its full health per
    /// `buildTime` engineer-ticks, in whole points.
    mutating func credit(_ b: Int, health full: Int, per buildTime: Int) {
        entities[b].healthCredit += full
        while entities[b].healthCredit >= buildTime && entities[b].health < entities[b].maxHealth {
            entities[b].health += 1
            entities[b].healthCredit -= buildTime
        }
    }

    mutating func complete(_ b: Int) {
        guard let kind = entities[b].buildingKind else { return }
        entities[b].complete = true
        entities[b].healthCredit = 0
        entities[b].health = min(entities[b].health, entities[b].maxHealth)
        let p = entities[b].owner.rawValue
        housing[p] += tables.building(kind).housing
        record(.constructed(entities[b].id, kind), for: p)
    }

    mutating func finishResearch(_ b: Int) {
        guard let research = entities[b].research else { return }
        let p = entities[b].owner.rawValue
        entities[b].research = nil
        entities[b].researchProgress = 0
        if !players[p].has(research) { players[p].improvements.append(research) }
        record(.researched(research), for: p)
    }

    // MARK: Upgrades

    /// A warfighter becomes the kind it was paid to become, keeping its share of health.
    mutating func finishUpgrade(_ i: Int, to kind: UnitKind) {
        guard let old = entities[i].unitKind else { return }
        let stats = tables.unit(kind)
        let p = entities[i].owner.rawValue
        stampSight(of: i, by: -1)
        entities[i].kind = .unit(kind)
        entities[i].health = max(1, entities[i].health * stats.health / max(1, entities[i].maxHealth))
        entities[i].maxHealth = stats.health
        entities[i].sight = stats.sight
        entities[i].upgrade = nil
        stampSight(of: i, by: 1)
        population[p] += stats.population - tables.unit(old).population
    }

    // MARK: Buildings

    mutating func updateBuilding(_ b: Int) {
        guard entities[b].complete, let kind = entities[b].buildingKind else { return }
        if entities[b].cooldown > 0 { entities[b].cooldown -= 1 }
        if let attack = tables.building(kind).attack, entities[b].cooldown == 0 {
            let e = entities[b]
            if let target = nearestOpponent(of: teamOf(e.owner), minX: Double(e.origin.x), minY: Double(e.origin.y),
                                            maxX: Double(e.origin.x + e.size.x), maxY: Double(e.origin.y + e.size.y),
                                            within: attack.range, visibleOnly: false) {
                strike(from: b, at: target, attack: attack)
                entities[b].cooldown = attack.interval
            }
        }
        if let head = entities[b].queue.first {
            let stats = tables.unit(head)
            if entities[b].trainProgress < stats.trainTime { entities[b].trainProgress += 1 }
            let p = entities[b].owner.rawValue
            if entities[b].trainProgress >= stats.trainTime && population[p] + stats.population <= populationLimit(p) {
                entities[b].queue.removeFirst()
                entities[b].trainProgress = 0
                let spot = freeTile(besideBuilding: b, index: entities[b].spawned)
                entities[b].spawned += 1
                let id = spawnPerson(head, owner: entities[b].owner, at: spot.centre)
                record(.trained(id, head), for: p)
            }
        }
    }
}
