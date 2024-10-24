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
local config = require "core.config"
local keymap = require "core.keymap"
local TreeView = require "core.treeview"
local ToolBar = require "plugins.toolbarview"

-- options
local display_side = "left" -- or "right"
local toolbar_location = "top" -- or "bottom"
-- local toolbar_location = "bottom"


-- |---------------------------|
-- |        ProjectView        |
-- |---------------------------|

-- the projectview plugin displays the file system for the project in a treeview

local toolbar = ToolBar()

local ProjectView = View:extend()

function ProjectView:new()
    ProjectView.super.new(ProjectView)
    ProjectView.node = core.root_view:get_active_node():split( display_side, toolbar, {y = true})
   --  add the treew view for the project files
end



-- get the files







-- pass the files to tree view




-- function ProjectView:add_view(view)
--   local split_direction = "down"
--   -- if adding the first section split based on toolbar_location
--   if ProjectView.node.views[1] and ProjectView.node.views[1]:is(ToolBar) then
--     split_direction = toolbar_location == "top" and "down" or "up"
--   end
--   ProjectView.node = ProjectView.node:split( split_direction, view, {y=false, x=true}, true)
-- end




-- |--------------------|
-- |        Init        |
-- |--------------------|

local projectview = ProjectView()




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



