-- mod-version:3
local core = require "core"
local View = require "core.view"
local RootView = require "core.rootview"
local EmptyView = require "core.emptyview"
local CommandView = require "core.commandview"
local ContextMenu = require "core.contextmenu"
local style = require "core.style"
local common = require "core.common"
local command = require "core.command"
local keymap = require "core.keymap"
local TreeView = require "core.treeview"
local ToolBar = require "plugins.toolbarview"

-- options
local display_side = "left" -- or "right"
local toolbar_location = "top" -- or "bottom"
-- local toolbar_location = "bottom"

-- |-----------------------------|
-- |        SectionHeader        |
-- |-----------------------------|

local Section = View:extend()


function Section:new(title)
  Section.super.new(self)
  self.title = title
  self.visible = true
  self.init_size = true
  self.tooltip = false
  self.size.y = 40
end

function Section:draw()
  local x, y = self:get_content_offset()
  local w, h = self.size.x, self.size.y
  renderer.draw_rect(x, y, w, h, style.accent)
end




function Section:update()
   print("section height", self.size.y)
   self.size.y = 40

   -- self:move_towards(self.size, "y", style.font:get_height() + style.padding.y * 2)
   -- Section.super.update(self)
end

function Section:set_target_size(axis, value)
   if axis == "y" then
      self.target_size = 30
      return true
   end
end

function Section:on_mouse_pressed(button, x, y, clicks)
  -- if not self.visible then return end
  -- local caught = Section.super.on_mouse_pressed(self, button, x, y, clicks)
  -- if caught then return caught end
  -- core.set_active_view(core.last_active_view)
  -- if self.hovered_item and command.is_valid(self.hovered_item.command) then
  --   command.perform(self.hovered_item.command)
  -- end
  -- return true
end












-- |------------------------|
-- |        Explorer        |
-- |------------------------|

local toolbar = ToolBar()
local toolbar2 = ToolBar()

local Explorer = View:extend()

function Explorer:new()
    Explorer.super.new( self )

    self.node = core.root_view:get_active_node():split( display_side, toolbar, {y = true})
    -- create an option for the toolbar to be on top or bottom
end


function Explorer:draw()
  self:draw_background(style.background)
end



function Explorer:add_view(view, ...)
  local split_direction = "down"
  -- if adding the first section split based on toolbar_location
  if self.node.views[1] and self.node.views[1]:is(ToolBar) then
    split_direction = toolbar_location == "top" and "down" or "up"
  end
  self.node = self.node:split( split_direction, view, ...)
end

function Explorer:add_section( title, view )
  -- add a section header
  local section_header = Section(title)
  self:add_view(section_header, {})

--   add section to a list to check for mouse clicks


   -- local draw_view = view.draw
   -- local view_get_content_offset = view.get_content_offset
   -- local section_height = 35

   -- function view:draw()
   --    draw_view(self)
   --    local x, y = view_get_content_offset(self)
   --    local w, h = self.size.x, section_height
   --    renderer.draw_rect(x, y, w, h, style.accent)
   -- end

   -- function view:get_content_offset()
   --    local x, y = view_get_content_offset(self)
   --    return x, y + section_height
   -- end


  -- add the view
  self:add_view(view, {y=false, x=true}, true)
end



















-- |--------------------|
-- |        Init        |
-- |--------------------|

local explorer = Explorer()




local folder = TreeView()
folder.items = { {
    label = "1",
    icon = { "D", "d" },
    expanded = true,
    items = { {
        label = "Folder",
        icon = { "D", "d" },
        items = { {
            label = "another",
            icon = "f"
         }, {
            label = "Folder2",
            icon = { "D", "d" },
            items = { {
                label = "nope",
                icon = "f"
             } }
         } }
     }, {
        label = "world",
        icon = "f"
     }, {
        label = "this is an item with a really long label that will overrun the width"
     } }
 }, {
    label = "again",
    icon = "f"
 }, {
    label = "hello",
    icon = { "D", "d" },
    expanded = true,
    items = { {
        label = "Folder",
        icon = { "D", "d" },
        items = { {
            label = "another",
            icon = "f"
         }, {
            label = "Folder2",
            icon = { "D", "d" },
            items = { {
                label = "nope",
                icon = "f"
             } }
         } }
     }, {
        label = "world",
        icon = "f"
     }, {
        label = "this is an item with a really long label that will overrun the width"
     } }
 }, {
    label = "again",
    icon = "f"
 } }

local folder2 = TreeView()
folder2.items = { {
    label = "2",
    icon = { "D", "d" },
    expanded = true,
    items = { {
        label = "Folder",
        icon = { "D", "d" },
        items = { {
            label = "another",
            icon = "f"
         }, {
            label = "Folder2",
            icon = { "D", "d" },
            items = { {
                label = "nope",
                icon = "f"
             } }
         } }
     }, {
        label = "world",
        icon = "f"
     }, {
        label = "this is an item with a really long label that will overrun the width"
     } }
 }, {
    label = "again",
    icon = "f"
 }, {
    label = "hello",
    icon = { "D", "d" },
    expanded = true,
    items = { {
        label = "Folder",
        icon = { "D", "d" },
        items = { {
            label = "another",
            icon = "f"
         }, {
            label = "Folder2",
            icon = { "D", "d" },
            items = { {
                label = "nope",
                icon = "f"
             } }
         } }
     }, {
        label = "world",
        icon = "f"
     }, {
        label = "this is an item with a really long label that will overrun the width"
     } }
 }, {
    label = "again",
    icon = "f"
 } }


 explorer:add_section("section1",folder)
 explorer:add_section("section2",folder2)


-- selecting an item in one section will need to deselect any item in other sections

-- function Explorer:new()
--   Explorer.super.new(self)
-- end

--   explorer commands
-- ---------------------

-- local previous_view

-- command.add( nil, {
--     ["explorer:toggle"] = function()
--         file_tree.visible = not file_tree.visible
--         if not file_tree.visible and core.active_view:is( file_tree ) then
--             local previous_view
--             if core.last_active_view:is( CommandView ) then
--                 previous_view = core.root_view:get_primary_node().active_view
--             else
--                 previous_view = core.last_active_view
--             end
--             core.set_active_view( previous_view )
--         end
--     end,

--     ["explorer:toggle-focus"] = function()
--         if not core.active_view:is( file_tree ) then
--             if core.active_view:is( CommandView ) then
--                 previous_view = core.last_active_view
--             else
--                 previous_view = core.active_view
--             end
--             if not previous_view then
--                 previous_view = core.root_view:get_primary_node().active_view
--             end
--             core.set_active_view( file_tree )
--             if (not file_tree.visible) then
--                 file_tree.visible = true
--             end
--             if not file_tree.selected_item then
--                 file_tree:set_selection_by_index( 1 )
--             end
--         else
--             core.set_active_view( previous_view or core.root_view:get_primary_node().active_view )
--         end
--     end
--  } )

-- --   explorer context menu
-- -- -------------------------
-- local menu = ContextMenu()

-- local show_menu = menu.show
-- function menu:show(...)
--   section_tree.scrollable = false
--   show_menu(self,...)
-- end

-- local hide_menu = menu.hide
-- function menu:hide(...)
--   section_tree.scrollable = true
--   hide_menu(self,...)
-- end

-- local on_view_mouse_pressed = RootView.on_view_mouse_pressed
-- local on_mouse_moved = RootView.on_mouse_moved
-- local root_view_update = RootView.update
-- local root_view_draw = RootView.draw

-- function RootView:on_mouse_moved(...)
--   if menu:on_mouse_moved(...) then return end
--   on_mouse_moved(self, ...)
-- end

-- function RootView.on_view_mouse_pressed(button, x, y, clicks)
--   -- We give the priority to the menu to process mouse pressed events.
--   -- if button == "right" then
--   --   section_tree.tooltip.alpha = 0
--   --   section_tree.tooltip.x, section_tree.tooltip.y = nil, nil
--   -- end
--   local handled = menu:on_mouse_pressed(button, x, y, clicks)
--   return handled or on_view_mouse_pressed(button, x, y, clicks)
-- end

-- function RootView:update(...)
--   root_view_update(self, ...)
--   menu:update()
-- end

-- function RootView:draw(...)
--   root_view_draw(self, ...)
--   menu:draw()
-- end

-- local on_quit_project = core.on_quit_project
-- function core.on_quit_project()
--   section_tree.cache = {}
--   on_quit_project()
-- end

-- local function is_project_folder(path)
--   for _,dir in pairs(core.project_directories) do
--     if dir.name == path then
--       return true
--     end
--   end
--   return false
-- end

-- local function is_primary_project_folder(path)
--   return core.project_dir == path
-- end

-- menu:register(function() return core.active_view:is(section_tree) and section_tree.selected_item end, {
--   { text = "Open in System", command = "treeview:open-in-system" },
--   ContextMenu.DIVIDER
-- })

-- menu:register(
--   function()
--     local item = section_tree.selected_item
--     return core.active_view:is(section_tree) and item and not is_project_folder(item.abs_filename)
--   end,
--   {
--     { text = "Rename", command = "treeview:rename" },
--     { text = "Delete", command = "treeview:delete" },
--   }
-- )

-- menu:register(
--   function()
--     local item = section_tree.selected_item
--     return core.active_view:is(section_tree)
--   end,
--   {
--     { text = "New File", command = "treeview:new-file" },
--     { text = "New Folder", command = "treeview:new-folder" },
--   }
-- )

-- menu:register(
--   function()
--     local item = section_tree.selected_item
--     return core.active_view:is(section_tree) and item
--       and not is_primary_project_folder(item.abs_filename)
--       and is_project_folder(item.abs_filename)
--   end,
--   {
--     { text = "Remove directory", command = "treeview:remove-project-directory" },
--   }
-- )

--   explorer toolbar
-- --------------------

--   explorer items
-- ------------------

-- return explorer
