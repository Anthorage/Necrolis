
class UnitStats
    attr_accessor :health, :damage, :armor, :attack_speed, :move_speed, :sight_range, :range

    def initialize(hp, dmg=1, arm=0, aspd=1, mspd=1, sran=2, ran=1)
        if hp.is_a?(UnitStats)
            dmg,arm,aspd,mspd,sran,ran = hp.damage,hp.armor,hp.attack_speed,hp.move_speed,hp.sight_range,hp.range
            hp = hp.health
        end

        @health,@damage,@armor,@attack_speed,@move_speed,@sight_range,@range=hp.to_i,dmg.to_i,arm.to_i,aspd.to_f,mspd.to_f,sran.to_f,ran.to_f
    end

end


class UnitType
    attr_reader :id, :name, :stats, :graphid, :energy_cost, :corpses_cost

    # move_speed = TILES_PER_SECOND
    # attack_speed = SECONDS_PER_ATTACK
    # sight_range = TILES_SEEN
    # range = MAX_TILES_ATTACK_DISTANCE

    def initialize(id, rid, name, stats, ecost=15, ccost=1)
        @id = id
        @graphid = rid

        @name = name

        @stats = stats
        @energy_cost = ecost
        @corpses_cost = ccost
    end

end


class UnitMaster
    SKELETON = 96
    SOLDIER = 97
    KNIGHT = 99

    def initialize
        @everyone = {}
    end

    def add(who)
        @everyone[who.id] = who
    end

    def setup
        move = :move
        attack = :attack
        melee = 1.1

        skeleton = UnitType.new( SKELETON, 0, "Skeleton", UnitStats.new(2,1,4,1,2.5,5,melee), 15, 1 )
        soldier = UnitType.new( SOLDIER, 4, "Soldier", UnitStats.new(4,1,0,1,2.5,5,melee), 20, 1 )
        knight = UnitType.new( KNIGHT, 4, "Knight", UnitStats.new(8,2,0,1.1,2.3,5,melee), 50, 1 )

        lis = [skeleton, soldier, knight]

        lis.each { |u| self.add(u) }
    end

    def bring(id)
        return @everyone[id]
    end

    def by_name(name)
        @everyone.each_value do |v|
            return v if v.name == name
        end

        return nil
    end

    def self.get
        @@myself ||= UnitMaster.new()

        return @@myself
    end

end
