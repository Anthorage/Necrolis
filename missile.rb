require_relative 'entity'

require_relative 'missiletype'


class Missile < Entity

    def is_dead?
        @dead
    end

    def update(dt)
        if @dist <= 0.025 || @hits <= 0
            @dead = true
        end

        if !@dead
            self.move_pos( @cosx*@speed, @cosy*@speed )

            sx = ((@rect.x)/@home.space_hash.tile_x).to_i
            sy = ((@rect.y)/@home.space_hash.tile_y).to_i

            fx = ((@rect.x+@rect.w)/@home.space_hash.tile_x).to_i
            fy = ((@rect.y+@rect.h)/@home.space_hash.tile_y).to_i

            

            (sx..fx).each do |hpx|
                (sy..fy).each do |hpy|
                    @home.space_hash.get_grid(hpx, hpy).each do |tar|
                        if @owner.player.is_enemy?(tar.player) && !@collided.include?(tar) && tar.collides_with?(self)
                            @collided.add?(tar)
                            @hits -= 1

                            if @hits <= 0
                                @dead = true
                                break
                            end
                        end
                    end
                end
            end

        end
    end

    def draw
        @home.unit_texture[ @kind.graphid ].draw_rot(@x, @y, @z, @angle, 0.5, 0.5, @home.zoom_x, @home.zoom_y)
    end

    def self.create_polar(x1,y1,x2,y2,gid,owner,home)
        dist = Math.sqrt( (x2-x1)^2 + (y2-y1)^2 )
        angle = Math.atan2( y2-y1, x2-x1 )

        return Missile.new(x1,y1,angle,dist,gid,owner,home)
    end

    def initialize(x1,y1,angle,dist,gid,owner,damage,home)
        super x1, y1, ZOrder::UNITS, home.tile_sx, home.tile_sy

        @owner = owner
        @home = home

        @kind = MissileMaster.get.bring(gid)

        @damage = damage
        @dead = false

        @dist = dist
        @angle = angle
        @cosx = Math.cos(angle)
        @siny = Math.sin(angle)

        @collided = Set.new()

        @speed = @kind.speed
        @hits = @kind.hits
    end

end

