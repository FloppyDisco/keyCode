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
local toolbar_location = "up" -- or "down"
-- local toolbar_location = "bottom"

print( "----- loading projectview.lua" )
-- print(core.project_directories)
-- print(#core.project_directories)

-- |---------------------------|
-- |        ProjectView        |
-- |---------------------------|

-- the projectview plugin displays the file system for the project in a treeview

local toolbar = ToolBar()

local ProjectView = TreeView:extend()

function ProjectView:new()
    ProjectView.super.new( ProjectView )
    -- self.node = core.root_view:get_active_node():split(display_side, self, {x=true}, true)
    self.cache = {}
    -- self.tree = TreeView()
    -- self.views = {self.tree}
    -- for item in self:get_files() do
    --   print(item)
    -- end

    -- self.node = self.node:split(toolbar_location, toolbar,{y = true})
end

-- local first = true
-- function ProjectView:update()
--     ProjectView.super.update( self )
--     if self:check_cache() then
--         for item in self:visible_files() do
--             for k, v in pairs( item ) do
--                 print("--- ",k, v )
--             end
--         end
--     end
--     -- self.items = items
-- end

local function get_depth( filename )
    local n = 1
    for _ in filename:gmatch( PATHSEP ) do
        n = n + 1
    end
    return n
end

function ProjectView:get_cached( dir, file, directory_name )
    local directory_cache = self.cache[directory_name]
    if not directory_cache then
        directory_cache = {}
        self.cache[directory_name] = directory_cache
    end
    -- to discriminate top directories from regular files or subdirectories
    -- we add ':' at the end of the top directories' filename. it will be
    -- used only to identify the entry into the cache.
    local cache_name = file.filename .. (file.topdir and ":" or "")
    local cached_file = directory_cache[cache_name]
    if not cached_file or cached_file.type ~= file.type then
        cached_file = {}
        local basename = common.basename( file.filename )
        if file.topdir then
            cached_file.filename = basename
            cached_file.expanded = true
            cached_file.depth = 0
            cached_file.abs_filename = directory_name
        else
            cached_file.filename = file.filename
            cached_file.depth = get_depth( file.filename )
            cached_file.abs_filename = directory_name .. PATHSEP .. file.filename
        end
        cached_file.name = basename
        cached_file.type = file.type
        cached_file.dir_name = dir.name -- points to top level "dir" item
        directory_cache[cache_name] = cached_file
    end
    return cached_file
end

function ProjectView:invalidate_cache( dirname )
    for _, v in pairs( self.cache[dirname] ) do
        v.skip = nil
    end
end

function ProjectView:check_cache()
    local changes_to_directories = false
    for i = 1, #core.project_directories do
        local dir = core.project_directories[i]
        -- invalidate cache's skip values if directory is declared dirty
        if dir.is_dirty and self.cache[dir.name] then
            self:invalidate_cache( dir.name )
            changes_to_directories = true
        end
        dir.is_dirty = false
    end
    return changes_to_directories
end

-- create list of files

function ProjectView:visible_files()
    return coroutine.wrap( function()
        for k = 1, #core.project_directories do
            local current_directory = core.project_directories[k]
            local cache_of_directory = self:get_cached( current_directory, current_directory.item, current_directory.name )
            coroutine.yield( cache_of_directory )
            local i = 1
            if current_directory.files then -- if consumed max sys file descriptors this can be nil
                while i <= #current_directory.files and cache_of_directory.expanded do
                    local item = current_directory.files[i]
                    local cached = self:get_cached( current_directory, item, current_directory.name )
                    coroutine.yield( cached )
                    i = i + 1
                    if not cached.expanded then
                        if cached.skip then
                            i = cached.skip
                        else
                            local depth = cached.depth
                            while i <= #current_directory.files do
                                if get_depth( current_directory.files[i].filename ) <= depth then
                                    break
                                end
                                i = i + 1
                            end
                            cached.skip = i
                        end
                    end
                end -- while files
            end
        end -- for directories
        --  self.count_lines = count_lines
    end )
end

-- function TreeView:set_selection(selection, selection_y, center, instant)
--   self.selected_item = selection
--   if selection and selection_y
--       and (selection_y <= 0 or selection_y >= self.size.y) then
--     local lh = self:get_item_height()
--     if not center and selection_y >= self.size.y - lh then
--       selection_y = selection_y - self.size.y + lh
--     end
--     if center then
--       selection_y = selection_y - (self.size.y - lh) / 2
--     end
--     local _, y = self:get_content_offset()
--     self.scroll.to.y = selection_y - y
--     self.scroll.to.y = common.clamp(self.scroll.to.y, 0, self:get_scrollable_size() - self.size.y)
--     if instant then
--       self.scroll.y = self.scroll.to.y
--     end
--   end
-- end

-- ---Sets the selection to the file with the specified path.
-- ---
-- ---@param path string #Absolute path of item to select
-- ---@param expand boolean #Expand dirs leading to the item
-- ---@param scroll_to boolean #Scroll to make the item visible
-- ---@param instant boolean #Don't animate the scroll
-- ---@return table? #The selected item
-- function TreeView:set_selection_to_path(path, expand, scroll_to, instant)
--   local to_select, to_select_y
--   local let_it_finish, done
--   ::restart::
--   for item, x,y,w,h in self:each_item() do
--     if not done then
--       if item.type == "dir" then
--         local _, to = string.find(path, item.abs_filename..PATHSEP, 1, true)
--         if to and to == #item.abs_filename + #PATHSEP then
--           to_select, to_select_y = item, y
--           if expand and not item.expanded then
--             -- Use TreeView:toggle_expand to update the directory structure.
--             -- Directly using item.expanded doesn't update the cached tree.
--             self:toggle_expand(true, item)
--             -- Because we altered the size of the TreeView
--             -- and because TreeView:get_scrollable_size uses self.count_lines
--             -- which gets updated only when TreeView:each_item finishes,
--             -- we can't stop here or we risk that the scroll
--             -- gets clamped by View:clamp_scroll_position.
--             let_it_finish = true
--             -- We need to restart the process because if TreeView:toggle_expand
--             -- altered the cache, TreeView:each_item risks looping indefinitely.
--             goto restart
--           end
--         end
--       else
--         if item.abs_filename == path then
--           to_select, to_select_y = item, y
--           done = true
--           if not let_it_finish then break end
--         end
--       end
--     end
--   end
--   if to_select then
--     self:set_selection(to_select, scroll_to and to_select_y, true, instant)
--   end
--   return to_select
-- end

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
projectview.node = core.root_view:get_active_node():split( display_side, projectview, {
    x = true
 }, true )




local items = { {
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

--  projectview.tree.items = items

-- selecting an item in one section will need to deselect any item in other sections
return projectview
