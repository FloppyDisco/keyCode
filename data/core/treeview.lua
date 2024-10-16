-- mod-version:3
local core = require "core"
local common = require "core.common"
local command = require "core.command"
local config = require "core.config"
local keymap = require "core.keymap"
local style = require "core.style"
local View = require "core.view"

-- |------------------------|
-- |        TreeView        |
-- |------------------------|

--[[
  treeview needs to be passed an array of tables
  treeview.items = {
    {
      label:string = "" -- the displayed text for the item
      items: array = {} -- the array of items to be nested under this item
      expanded: boolean = true -- determines whether or not to show the nested items

      ...additional item data
    },

    ...
  }

  if an item has an 'items' property then it will be treated as an expandable obj,
  if no expanded property is passed it will default to true
    if it does not, it will be treated as a leaf
    if it does not, any 'expanded' property will be ignored
]]

local TreeView = View:extend()

function TreeView:new()
  TreeView.super.new(self)
  self.scrollable = true
  self.visible = true
  self.init_size = true
  self.target_size = config.plugins.treeview.size
  self.cache = {}
  self.tooltip = { x = 0, y = 0, begin = 0, alpha = 0 }
  self.count_lines = 0
  self.last_scroll_y = 0
  self.item_icon_width = 0
  self.item_text_spacing = 0
  self.tree_spacing = 6
  self.items = {}
end


local tooltip_offset = style.font:get_height()
local tooltip_border = 1
local tooltip_delay = 0.5
local tooltip_alpha = 255
local tooltip_alpha_rate = 1


local function get_depth(filename)
  local n = 1
  for _ in filename:gmatch(PATHSEP) do
    n = n + 1
  end
  return n
end

local function replace_alpha(color, alpha)
  local r, g, b = table.unpack(color)
  return { r, g, b, alpha }
end



function TreeView:set_target_size(axis, value)
  if axis == "x" then
    self.target_size = value
    return true
  end
end


function TreeView:get_name()
  return nil
end


function TreeView:get_item_height()
  return style.font:get_height() + style.padding.y
end


function TreeView:each_item()
  return coroutine.wrap(function()
    local count_lines = 0
    local left_edge, top_edge = self:get_content_offset()
    local item_vertical_offset = top_edge + style.padding.y
    local width = self.size.x
    local item_height = self:get_item_height()

    local function yield_item(item, item_left_side)
      coroutine.yield(item, item_left_side, item_vertical_offset, width, item_height)
      count_lines = count_lines + 1
      item_vertical_offset = item_vertical_offset + item_height
    end

    local function display_items(items, group_left_side)
      for i,item in ipairs(items) do
        yield_item(item, group_left_side)
        if item.items and item.expanded then
          display_items(item.items, group_left_side + self.tree_spacing)
        end
      end
    end

    display_items(self.items, left_edge)
    self.count_lines = count_lines
      -- local dir = core.project_directories[k]
      -- local dir_cached = self:get_cached(dir, dir.item, dir.name)
      -- coroutine.yield(dir_cached, left_edge, item_vertical_offset, width, item_height)
      -- count_lines = count_lines + 1
      -- local i = 1
      -- if dir.files then -- if consumed max sys file descriptors this can be nil
      --   while i <= #dir.files and dir_cached.expanded do
      --     local item = dir.files[i]
      --     local cached = self:get_cached(dir, item, dir.name)

      --     coroutine.yield(cached, left_edge, item_vertical_offset, width, item_height)
      --     count_lines = count_lines + 1
      --     item_vertical_offset = item_vertical_offset + item_height
      --     i = i + 1

      --     if not cached.expanded then
      --       if cached.skip then
      --         i = cached.skip
      --       else
      --         local depth = cached.depth
      --         while i <= #dir.files do
      --           if get_depth(dir.files[i].filename) <= depth then break end
      --           i = i + 1
      --         end
      --         cached.skip = i
      --       end
      --     end
      --   end -- while files
      -- end

  end)
end


function TreeView:set_selection(selection, selection_y, center, instant)
  self.selected_item = selection
  if selection and selection_y
      and (selection_y <= 0 or selection_y >= self.size.y) then
    local lh = self:get_item_height()
    if not center and selection_y >= self.size.y - lh then
      selection_y = selection_y - self.size.y + lh
    end
    if center then
      selection_y = selection_y - (self.size.y - lh) / 2
    end
    local _, y = self:get_content_offset()
    self.scroll.to.y = selection_y - y
    self.scroll.to.y = common.clamp(self.scroll.to.y, 0, self:get_scrollable_size() - self.size.y)
    if instant then
      self.scroll.y = self.scroll.to.y
    end
  end
end

function TreeView:get_text_bounding_box(item, x, y, w, h)
  local icon_width = style.icon_font:get_width("D")
  local xoffset = item.depth * style.padding.x + style.padding.x + icon_width
  x = x + xoffset
  w = style.font:get_width(item.name) + 2 * style.padding.x
  return x, y, w, h
end

function TreeView:on_mouse_moved(px, py, ...)
  if not self.visible then return end
  if TreeView.super.on_mouse_moved(self, px, py, ...) then
    -- mouse movement handled by the View (scrollbar)
    self.hovered_item = nil
    return
  end

  local item_changed, tooltip_changed
  for item, x,y,w,h in self:each_item() do
    if px > x and py > y and px <= x + w and py <= y + h then
      item_changed = true
      self.hovered_item = item

      x,y,w,h = self:get_text_bounding_box(item, x,y,w,h)
      if px > x and py > y and px <= x + w and py <= y + h then
        tooltip_changed = true
        self.tooltip.x, self.tooltip.y = px, py
        self.tooltip.begin = system.get_time()
      end
      break
    end
  end
  if not item_changed then self.hovered_item = nil end
  if not tooltip_changed then self.tooltip.x, self.tooltip.y = nil, nil end
end


function TreeView:on_mouse_left()
  TreeView.super.on_mouse_left(self)
  self.hovered_item = nil
end

local on_mouse_pressed = TreeView.on_mouse_pressed
function TreeView:on_mouse_pressed(...)
  self.selected_item = self.hovered_item
  self.hovered_item = nil
  on_mouse_pressed(self,...)
end

function TreeView:update()
  -- update width
  local dest = self.visible and self.target_size or 0
  if self.init_size then
    self.size.x = dest
    self.init_size = false
  else
    self:move_towards(self.size, "x", dest, nil, "treeview")
  end

  if self.size.x == 0 or self.size.y == 0 or not self.visible then return end

  local duration = system.get_time() - self.tooltip.begin
  if self.hovered_item and self.tooltip.x and duration > tooltip_delay then
    self:move_towards(self.tooltip, "alpha", tooltip_alpha, tooltip_alpha_rate, "treeview")
  else
    self.tooltip.alpha = 0
  end

  self.item_icon_width = style.icon_font:get_width("D")
  self.item_text_spacing = style.icon_font:get_width("f") / 2

  -- this will make sure hovered_item is updated
  local dy = math.abs(self.last_scroll_y - self.scroll.y)
  if dy > 0 then
    self:on_mouse_moved(core.root_view.mouse.x, core.root_view.mouse.y, 0, 0)
    self.last_scroll_y = self.scroll.y
  end

  TreeView.super.update(self)
end

function TreeView:get_scrollable_size()
  return self.count_lines and self:get_item_height() * (self.count_lines + 1) or math.huge
end

function TreeView:draw_tooltip()
  local text = common.home_encode(self.hovered_item.abs_filename)
  local w, h = style.font:get_width(text), style.font:get_height(text)

  local x, y = self.tooltip.x + tooltip_offset, self.tooltip.y + tooltip_offset
  w, h = w + style.padding.x, h + style.padding.y

  if x + w > core.root_view.root_node.size.x then -- check if we can span right
    x = x - w -- span left instead
  end

  local bx, by = x - tooltip_border, y - tooltip_border
  local bw, bh = w + 2 * tooltip_border, h + 2 * tooltip_border
  renderer.draw_rect(bx, by, bw, bh, replace_alpha(style.text, self.tooltip.alpha))
  renderer.draw_rect(x, y, w, h, replace_alpha(style.background2, self.tooltip.alpha))
  common.draw_text(style.font, replace_alpha(style.text, self.tooltip.alpha), text, "center", x, y, w, h)
end


function TreeView:get_item_icon(item, active, hovered)
  local character = "f"
  if item.type == "dir" then
    character = item.expanded and "D" or "d"
  end
  local font = style.icon_font
  local color = style.text
  if active or hovered then
    color = style.accent
  end
  return character, font, color
end

function TreeView:get_item_text(item, active, hovered)
  local text = item.name
  local font = style.font
  local color = style.text
  if active or hovered then
    color = style.accent
  end
  return text, font, color
end


function TreeView:draw_item_text(item, active, hovered, x, y, w, h)
  local item_text, item_font, item_color = self:get_item_text(item, active, hovered)
  common.draw_text(item_font, item_color, item_text, nil, x, y, 0, h)
end


function TreeView:draw_item_icon(item, active, hovered, x, y, w, h)
  local icon_char, icon_font, icon_color = self:get_item_icon(item, active, hovered)
  common.draw_text(icon_font, icon_color, icon_char, nil, x, y, 0, h)
  return self.item_icon_width + self.item_text_spacing
end


function TreeView:draw_item_body(item, active, hovered, x, y, w, h)
    x = x + self:draw_item_icon(item, active, hovered, x, y, w, h)
    self:draw_item_text(item, active, hovered, x, y, w, h)
end


function TreeView:draw_item_chevron(item, active, hovered, x, y, w, h)
  if item.type == "dir" then
    local chevron_icon = item.expanded and "-" or "+"
    local chevron_color = hovered and style.accent or style.text
    common.draw_text(style.icon_font, chevron_color, chevron_icon, nil, x, y, 0, h)
  end
  return style.padding.x
end


function TreeView:draw_item_background(item, active, hovered, x, y, w, h)
  if hovered then
    local hover_color = { table.unpack(style.line_highlight) }
    hover_color[4] = 160
    renderer.draw_rect(x, y, w, h, hover_color)
  elseif active then
    renderer.draw_rect(x, y, w, h, style.line_highlight)
  end
end


function TreeView:draw_item(item, active, hovered, x, y, w, h)
  self:draw_item_background(item, active, hovered, x, y, w, h)
  -- x = x + item.depth * style.padding.x + style.padding.x
  -- x = x + self:draw_item_chevron(item, active, hovered, x, y, w, h)
  -- self:draw_item_body(item, active, hovered, x, y, w, h)
end


function TreeView:draw()
  if not self.visible then return end
  self:draw_background(style.background2)
  local _y, _h = self.position.y, self.size.y

  for item, x,y,w,h in self:each_item() do
    if y + h >= _y and y < _y + _h then
      self:draw_item(item,
        item == self.selected_item,
        item == self.hovered_item,
        x, y, w, h)
    end
  end

  self:draw_scrollbar()
  if self.hovered_item and self.tooltip.x and self.tooltip.alpha > 0 then
    core.root_view:defer_draw(self.draw_tooltip, self)
  end
end


function TreeView:get_parent(item)
  local parent_path = common.dirname(item.abs_filename)
  if not parent_path then return end
  for it, _, y in self:each_item() do
    if it.abs_filename == parent_path then
      return it, y
    end
  end
end


function TreeView:get_item(item, where)
  local last_item, last_x, last_y, last_w, last_h
  local stop = false

  for it, x, y, w, h in self:each_item() do
    if not item and where >= 0 then
      return it, x, y, w, h
    end
    if item == it then
      if where < 0 and last_item then
        break
      elseif where == 0 or (where < 0 and not last_item) then
        return it, x, y, w, h
      end
      stop = true
    elseif stop then
      item = it
      return it, x, y, w, h
    end
    last_item, last_x, last_y, last_w, last_h = it, x, y, w, h
  end
  return last_item, last_x, last_y, last_w, last_h
end

function TreeView:get_next(item)
  return self:get_item(item, 1)
end

function TreeView:get_previous(item)
  return self:get_item(item, -1)
end

function TreeView:toggle_expand(toggle, item)
  item = item or self.selected_item
  if not item then return end
  if item.items then
    if type(toggle) == "boolean" then
      item.expanded = toggle
    else
      item.expanded = not item.expanded
    end
  end
end


local view = TreeView()

local previous_view

-- Register the TreeView commands and keymap
command.add(nil, {
  ["treeview:toggle"] = function()
    view.visible = not view.visible
    if not view.visible and core.active_view:is(TreeView) then
      local previous_view
      if core.last_active_view:is(CommandView) then
        previous_view = core.root_view:get_primary_node().active_view
      else
        previous_view = core.last_active_view
      end
      core.set_active_view(previous_view)
    end
  end,

  ["treeview:toggle-focus"] = function()
    if not core.active_view:is(TreeView) then
      if core.active_view:is(CommandView) then
        previous_view = core.last_active_view
      else
        previous_view = core.active_view
      end
      if not previous_view then
        previous_view = core.root_view:get_primary_node().active_view
      end
      core.set_active_view(view)
      if(not view.visible)then
        view.visible = true
      end
      if not view.selected_item then
        for it, _, y in view:each_item() do
          view:set_selection(it, y)
          break
        end
      end

    else
      core.set_active_view(
        previous_view or core.root_view:get_primary_node().active_view
      )
    end
  end
})

command.add(
  function()
    return core.active_view:extends(TreeView), TreeView
  end, {
  ["treeview:next"] = function()
    local item, _, item_y = view:get_next(view.selected_item)
    view:set_selection(item, item_y)
  end,

  ["treeview:previous"] = function()
    local item, _, item_y = view:get_previous(view.selected_item)
    view:set_selection(item, item_y)
  end,

  ["treeview:deselect"] = function()
    view.selected_item = nil
  end,

  ["treeview:select"] = function()
    -- this does not seem right
    view:set_selection(view.hovered_item)
  end,

  ["treeview:collapse"] = function()
    if view.selected_item then
      if view.selected_item.type == "dir" and view.selected_item.expanded then
        view:toggle_expand(false)
      else
        local parent_item, y = view:get_parent(view.selected_item)
        if parent_item then
          view:set_selection(parent_item, y)
        end
      end
    end
  end,

  ["treeview:expand"] = function()
    local item = view.selected_item
    if not item or item.type ~= "dir" then return end

    if item.expanded then
      local next_item, _, next_y = view:get_next(item)
      if next_item.depth > item.depth then
        view:set_selection(next_item, next_y)
      end
    else
      view:toggle_expand(true)
    end
  end,
})

keymap.add {
  ["ctrl+\\"]     = "treeview:toggle",
  ["up"]          = "treeview:previous",
  ["down"]        = "treeview:next",
  ["escape"]      = "treeview:deselect",
  ["left"]        = "treeview:collapse",
  ["right"]       = "treeview:expand",
-- cmd+up move up a section
-- cmd+down move down a section
}

return view
