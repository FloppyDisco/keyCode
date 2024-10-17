-- mod-version:3
local core = require "core"
local View = require "core.view"
local RootView = require "core.rootview"
local CommandView = require "core.commandview"
local ContextMenu = require "core.contextmenu"
local command = require "core.command"
local keymap = require "core.keymap"
local TreeView = require "core.treeview"

-- |------------------------|
-- |        FileTree        |
-- |------------------------|

local display_side = "left" -- or "right"


-- :add_section("section title", view)
  -- splits the filetree with another view
  --

-- init()
  -- adds a section for each project directory


  --   Init
-- --------
local filetree = View()


filetree.node = core.root_view:get_active_node():split(display_side, nil, {x = true}, true)

-- add toolbar
-- add section for each project_dir
-- for each project

function filetree:add_section(section_title, view)

  filetree.node = filetree.node:split("up", view, {x=true}, true)
  -- filetree.node = filetree.node:split("up", nil)

end


-- selecting an item in one section will need to deselect any item in other sections




-- local Section = View:extend()
-- filetree.section = Section

-- function Section:new()
--   Section.super.new(self)
--   self.scrollable = false
--   self.visible = true
--   self.init_size = true
--   self.target_size = 200
--   self.item_icon_width = 0
--   self.item_text_spacing = 0
-- end


-- function Section:draw()
-- end


local section_tree = TreeView()
-- filetree.tree_spacing = 40


section_tree.items = {
    {
        label= "hello",
        icon={"D","d"},
        expanded = true,
        items = {
            {
                label = "Folder",
                icon={"D","d"},
                items = {
                    {
                        label = "another",
                        icon = "f",
                    },
                    {
                        label = "Folder2",
                        icon={"D","d"},
                        items = {
                            {
                                label = "nope",
                                icon = "f",
                            }
                        }
                    },
                }
            },
            {
                label = "world",
                icon = "f"
            },
            {
                label = "this is an item with a really long label that will overrun the width",
            }
        }
    },
    {
        label = "again",
        icon="f"
    },
    {
        label= "hello",
        icon={"D","d"},
        expanded = true,
        items = {
            {
                label = "Folder",
                icon={"D","d"},
                items = {
                    {
                        label = "another",
                        icon = "f",
                    },
                    {
                        label = "Folder2",
                        icon={"D","d"},
                        items = {
                            {
                                label = "nope",
                                icon = "f",
                            }
                        }
                    },
                }
            },
            {
                label = "world",
                icon = "f"
            },
            {
                label = "this is an item with a really long label that will overrun the width",
            }
        }
    },
    {
        label = "again",
        icon="f"
    }
}



filetree:add_section("project", section_tree)

--   filetree commands
-- ---------------------

local previous_view

command.add(nil, {
  ["filetree:toggle"] = function()
    section_tree.visible = not section_tree.visible
    if not section_tree.visible and core.active_view:is(section_tree) then
      local previous_view
      if core.last_active_view:is(CommandView) then
        previous_view = core.root_view:get_primary_node().active_view
      else
        previous_view = core.last_active_view
      end
      core.set_active_view(previous_view)
    end
  end,

  ["filetree:toggle-focus"] = function()
    if not core.active_view:is(section_tree) then
      if core.active_view:is(CommandView) then
        previous_view = core.last_active_view
      else
        previous_view = core.active_view
      end
      if not previous_view then
        previous_view = core.root_view:get_primary_node().active_view
      end
      core.set_active_view(section_tree)
      if(not section_tree.visible)then
        section_tree.visible = true
      end
      if not section_tree.selected_item then
        section_tree:set_selection_by_index(1)
      end
    else
      core.set_active_view(
        previous_view or core.root_view:get_primary_node().active_view
      )
    end
  end
})

-- --   filetree context menu
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


--   filetree toolbar
-- --------------------



--   filetree items
-- ------------------





return filetree
