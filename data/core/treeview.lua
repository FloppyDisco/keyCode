-- mod-version:3
local core = require "core"
local common = require "core.common"
local command = require "core.command"
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

local treeview_size_interval = 140

local TreeView = View:extend()

function TreeView:new()
  TreeView.super.new(self)
  self.scrollable = true
  self.visible = true
  self.init_size = true
  self.target_size = 200
  self.count_lines = 0
  self.last_scroll_y = 0
  self.icon_font = style.icon_font
  self.icon_width = 0
  self.icon_spacing = 0
  self.tree_spacing = 0
  -- self.minimum_size = 80
  -- self.maximum_size = 0
  self.items = {}
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


--   draw visible items
-- ----------------------

function TreeView:each_item()
  return coroutine.wrap(function()
    local count_lines = 0
    local left_edge, top_edge = self:get_content_offset()
    local left_side = left_edge + style.padding.x
    local item_vertical_offset = top_edge + style.padding.y
    local width = self.size.x
    local item_height = self:get_item_height()

    local function yield_item(item, item_left_side)
      count_lines = count_lines + 1
      coroutine.yield(item, item_left_side, item_vertical_offset, width, item_height, count_lines)
      item_vertical_offset = item_vertical_offset + item_height
    end

    local function display_items(items, group_left_side, parent_item)
      for i,item in ipairs(items) do
        item.parent = parent_item
        yield_item(item, group_left_side)
        if item.items and item.expanded then
          display_items(item.items, group_left_side + self.tree_spacing, item)
        end
      end
    end

    display_items(self.items, left_side)
    self.count_lines = count_lines
  end)
end

-- close this value for updating
local default_tree_spacing = false

function TreeView:update()
  if self.tree_spacing == 0 then
    default_tree_spacing = true
  end
  if default_tree_spacing then
    self.tree_spacing = self.icon_font:get_width("-") * 1.8
  end
  self.icon_width = self.icon_font:get_width("f")
  self.icon_spacing = self.icon_font:get_width("f")/2

  -- self.maximum_size = core.window:get_size() - self.minimum_size
  -- if self.target_size > self.maximum_size then
  --   self.target_size = self.maximum_size
  -- end

  -- update width
  local dest = self.visible and self.target_size or 0
  if self.init_size then
    self.size.x = dest
    self.init_size = false
  else
    self:move_towards(self.size, "x", dest, nil, "treeview")
  end
  if self.size.x == 0 or self.size.y == 0 or not self.visible then return end
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

function TreeView:draw_item_text(item, active, hovered, x, y, w, h)
  local item_text, item_font, item_color = self:get_item_text(item, active, hovered)
  common.draw_text(item_font, item_color, item_text, nil, x, y, 0, h)
end

function TreeView:draw_item_icon(item, color, x, y, w, h)
    local expandable = item.items ~= nil
    local icon
    if expandable and type(item.icon) == "table" then
      icon = item.expanded and item.icon[1] or item.icon[2]
    else
      icon = item.icon
    end
    common.draw_text(style.icon_font, color, icon, nil, x, y, 0, h)
    return self.icon_width + self.icon_spacing
end

function TreeView:draw_expand_chevron(item, color, x, y, w, h)
  if item.items then -- item is expandable
    local chevron_icon = item.expanded and "-" or "+"
    if item.expanded == nil then item.expanded = false end
    common.draw_text(self.icon_font, color, chevron_icon, nil, x, y, 0, h)
  end
  return  self.icon_font:get_width("-") * 1.8
end

function TreeView:draw_item_background(item, active, hovered, x, y, w, h)
  if hovered then
    local hover_color
    if style.hover_background_color then
      hover_color = style.hover_background_color
    else
      hover_color = { table.unpack(style.line_highlight) }
      hover_color[4] = 150
    end
    renderer.draw_rect(x, y, w, h, hover_color)
  elseif active then
    renderer.draw_rect(x, y, w, h, style.line_highlight)
  end
end

function TreeView:draw_item(item, active, hovered, x, y, w, h)
  local left_edge, top_edge = self:get_content_offset()
  local color = (active or hovered) and style.accent or style.text
  self:draw_item_background(item, active, hovered, left_edge, y, w, h)
  x = x + self:draw_expand_chevron(item, color, x, y, w, h)
  if item.icon then
    x = x + self:draw_item_icon(item, color, x, y, w, h)
  end
  common.draw_text(style.font, color, item.label, nil, x, y, 0, h)
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
end

function TreeView:set_selection_by_index(selected_index)
  for item, x,y,w,h, index in self:each_item() do
    if index == selected_index then
      self.selected_item = item
      self.selected_item_index = selected_index
    end
  end
end

function TreeView:set_selection_by_item(selected_item)
  for item, x,y,w,h, index in self:each_item() do
    if item == selected_item then
      self.selected_item = selected_item
      self.selected_item_index = index
    end
  end
end

--   Mouse
-- ---------

-- decorate item on mouse hover
function TreeView:on_mouse_moved(px, py, ...)
  if not self.visible then return end
  if TreeView.super.on_mouse_moved(self, px, py, ...) then
    -- mouse movement handled by the View (scrollbar)
    self.hovered_item = nil
    return
  end
  local hovering_over_an_item = false
  local hovered_item, hovered_item_index = self:get_item_from_mouse_position(px,py)
  if hovered_item then
    self.hovered_item = hovered_item
    self.hovered_item_index = hovered_item_index
    hovering_over_an_item = true
  end
  if not hovering_over_an_item then self.hovered_item = nil end
end

function TreeView:on_mouse_left()
  TreeView.super.on_mouse_left(self)
  self.hovered_item = nil
end

-- select item on mouse press
local on_mouse_pressed = TreeView.on_mouse_pressed
function TreeView:on_mouse_pressed(...)
  -- if not self.hovered_item then
    -- select clicked item
    self.selected_item = self.hovered_item
    self.selected_item_index = self.hovered_item_index
    self.hovered_item = nil
    -- toggle expandable items
    if self.selected_item and self.selected_item.items ~= nil then
      self.selected_item.expanded = not self.selected_item.expanded
    end
  -- end
  on_mouse_pressed(self,...)
end

function TreeView:get_item_from_mouse_position(px, py)
    -- x and w can be determined from the view, not the Item
    -- this will reduce checks
    for item, x,y,w,h, index in self:each_item() do
      if px > x and py > y and px <= x + w and py <= y + h then
        return item, index
      end
    end
end

--   Commands
-- ------------

command.add(
  function()
    local view = core.active_view
    return view:extends(TreeView), view
  end, {
  ["treeview:next"] = function(view)
    if view.selected_item_index then
      view:set_selection_by_index(view.selected_item_index + 1)
    else
      view:set_selection_by_index(1)
    end
  end,

  ["treeview:previous"] = function(view)
    -- what to do when there is no selection
    if view.selected_item_index then
      view:set_selection_by_index(view.selected_item_index - 1)
    else
      view:set_selection_by_index(1)
    end
  end,

  ["treeview:deselect"] = function(view)
    view.selected_item = nil
    view.selected_item_index = nil
  end,

  ["treeview:expand"] = function(view)
    local item = view.selected_item
    if not item or not item.items then return end
    if item.expanded then -- already expanded, move to next item
      view:set_selection_by_index(view.selected_item_index + 1)
    else
      view.selected_item.expanded = true
    end
  end,

  ["treeview:collapse"] = function(view)
    local item = view.selected_item
    if item then
      if item.items ~= nil and item.expanded then
        view.selected_item.expanded = false
      else -- already collapsed, move to parent item
        if item.parent then
          view:set_selection_by_item(item.parent)
        end
      end
    end
  end,

  ["treeview:collapse-all"] = function(view)
    local function collapse_items(items)
      for _,item in ipairs(items) do
        if item.items ~= nil then
          item.expanded = false
          for __, nested_item in ipairs(item.items) do
            collapse_items(item.items)
          end
        end
      end
    end
    collapse_items(view.items)
    view:set_selection_by_index(1)
  end,

  -- ["treeview:increase-size"] = function(view)
  --   local new_size = common.clamp(view.target_size + treeview_size_interval, view.minimum_size, view.maximum_size)
  --   view.target_size = new_size
  -- end,

  -- ["treeview:decrease-size"] = function(view)
  --   local new_size = common.clamp(view.target_size - treeview_size_interval, view.minimum_size, view.maximum_size)
  --   view.target_size = new_size
  -- end,

})

keymap.add {
  ["escape"]      = "treeview:deselect",
  ["up"]          = "treeview:previous",
  ["down"]        = "treeview:next",
  ["left"]        = "treeview:collapse",
  ["right"]       = "treeview:expand",
  -- ["ctrl+shift+="]= "treeview:increase-size",
  -- ["ctrl+-"]      = "treeview:decrease-size",
}

return TreeView
