-- mod-version:3
local draw_rect = renderer.draw_rect
function renderer.draw_rect(x, y, w, h, color, r)
    if r == nil then
        draw_rect(x,y,w,h,color)
    else
        -- draw upper segment with radius
        for i = 0, r do
            local b = r-i
            local offset = math.ceil(r - math.sqrt(r*r - b*b))
            draw_rect(x + offset, y + i, w - (2*offset), 0.5, color)
        end
        -- draw middle rectangular segment
        draw_rect(x, y + r, w, h - (r*2), color)
        -- draw lower segment with radius
        for i = r, 0, -1 do
            local b = r-i
            local offset = math.ceil(r - math.sqrt(r*r - b*b))
            draw_rect(x + offset, y + h - r + (r-i), w - (2*offset), 1, color)
        end
    end
end
