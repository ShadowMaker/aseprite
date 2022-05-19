#include "app/app.h"
#include "obs/signal.h"
#include "app/script/engine.h"
#include "app/script/luacpp.h"
#include "app/tools/ink.h"
#include "../laf/base/log.h"
#include "app/tools/lua_ink.h"
#include "app/tools/tool_loop.h"

namespace app
{
    namespace tools
    {
        LuaInk::LuaInk() {
            m_lastLoop = 0;
         }

        void LuaInk::inkHline(int x1, int y, int x2, ToolLoop *loop) 
        {
            switch(loop->getMouseButton())
            {
            case 0:
                if (m_lastLoop != loop && luaFunction != nullptr)
                {
                    m_lastLoop = loop;
                    luaFunction(x1, y, loop->getMouseButton());
                }
                break;
            case 1:
                if (luaFunction != nullptr)
                {
                    m_lastLoop = loop;
                    luaFunction(x1, y, loop->getMouseButton());
                }
                break;
            }
        };

        void LuaInk::prepareForPointShape(ToolLoop *loop, bool firstPoint, int x, int y) { }

        void LuaInk::prepareVForPointShape(ToolLoop *loop, int y) { }

        void LuaInk::prepareUForPointShapeWholeScanline(ToolLoop *loop, int x1) { }

        void LuaInk::prepareUForPointShapeSlicedScanline(ToolLoop *loop, bool leftSlice, int x1) { }
    }
}
