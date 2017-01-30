

class UnitGroup
    @@groups = []

    def size
        @units.size
    end

    def add(who)
        @units.add?(who)
        who.add_group(self)
    end

    def rem(who)
        @units.delete(who)
        who.rem_group(self)
    end

    def clear
        @units.each {|u| u.rem_group(self)}
        @units.clear
    end

    def self.clear
        @@groups.each {|g| g.clear}
        @@groups.clear
    end

    def initialize
        @units = Set.new()

        @@groups.push(self)
    end

end
