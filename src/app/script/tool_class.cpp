// Aseprite
// Copyright (C) 2019  Igara Studio S.A.
//
// This program is distributed under the terms of
// the End-User License Agreement for Aseprite.

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#include "app/app.h"
#include "obs/signal.h"
#include "app/script/engine.h"
#include "app/script/luacpp.h"
#include "app/tools/ink.h"
#include "app/tools/lua_ink.h"
#include "app/tools/tool.h"
#include "app/tools/tool_box.h"

namespace app {
namespace script {

namespace {

int create_ref(lua_State* L, bool weak_ref)
{
    lua_newtable(L); // new_table={}

    if (weak_ref) {
        lua_newtable(L); // metatable={}            

        lua_pushliteral(L, "__mode");
        lua_pushliteral(L, "v");
        lua_rawset(L, -3); // metatable._mode='v'

        lua_setmetatable(L, -2); // setmetatable(new_table,metatable)
    }

    lua_pushvalue(L,-2); // push the previous top of stack
    lua_rawseti(L,-2,1); // new_table[1]=original value on top of the stack

    //Now new_table is on top of the stack, rest is up to you
    //Here is how you would store the reference:
    return luaL_ref(L, LUA_REGISTRYINDEX); // this pops the new_table
}

//Add signal to LuaInk and call it?
//Check dialog widget
void Tool_connect_to_ink(lua_State* L, int toolIdx, app::tools::LuaInk* ink)
{
  int cIdx = luaL_ref(L, LUA_REGISTRYINDEX);
  int eIdx = luaL_ref(L, LUA_REGISTRYINDEX);

  LOG("Tool_connect_to_ink0 %d, %d\n", cIdx, eIdx);

  ink->luaFunction = [=](int x, int y, int button) {
      LOG("Lambda function is called from xy: %d, %d with button(%d)\n", x, y, button);
      if (button >= 0)
      {
        int d0 = lua_rawgeti(L, LUA_REGISTRYINDEX, cIdx);
        lua_pushinteger(L, x);
        lua_pushinteger(L, y);
        lua_pushinteger(L, button);
        lua_call( L, 3, 0);
      }
  };
}

int Tool_get_id(lua_State* L)
{
  auto tool = get_ptr<tools::Tool>(L, 1);
  lua_pushstring(L, tool->getId().c_str());
  return 1;
}

int Tool_set_onClick(lua_State* L)
{
  auto tool = get_ptr<tools::Tool>(L, 1);
  //app::tools::Ink* ink = tool->getInk(0);
  app::tools::LuaInk* ink = dynamic_cast<app::tools::LuaInk*>(tool->getInk(0));
  if (ink) 
  {
        LOG("TOOL: setonClick was called. And tool is LUA\n");
  } else {
        LOG("TOOL: setonClick was called. But tools is not LUA\n");  
  }

  int stackSize = lua_gettop(L);
  LOG("TOOL: setonClick was called. stackSize:%d\n", stackSize);  
  if (lua_isfunction(L,2))
  {
    Tool_connect_to_ink(L, 1, ink);
  }
  return 0;
}

const luaL_Reg Tool_methods[] = {
  { "setOnClick", Tool_set_onClick }
};

const Property Tool_properties[] = {
  { "id", Tool_get_id, nullptr },
  { nullptr, nullptr, nullptr }
};

} // anonymous namespace

using Tool = tools::Tool;
DEF_MTNAME(Tool);

void register_tool_class(lua_State* L)
{
  REG_CLASS(L, Tool);
  REG_CLASS_PROPERTIES(L, Tool);
}

void push_tool(lua_State* L, tools::Tool* tool)
{
  push_ptr<Tool>(L, tool);
}

tools::Tool* get_tool_from_arg(lua_State* L, int index)
{
  if (auto tool = may_get_ptr<tools::Tool>(L, index))
    return tool;
  else if (const char* id = lua_tostring(L, index))
    return App::instance()->toolBox()->getToolById(id);
  else
    return nullptr;
}

} // namespace script
} // namespace app
