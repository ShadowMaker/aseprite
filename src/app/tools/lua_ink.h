// This program is distributed under the terms of
// the End-User License Agreement for Aseprite.

namespace app
{
    namespace tools
    {
        class LuaInk : public Ink
        {
            public:
                class LuaPaintEvent {
                public:
                    int x;
                    int y;
                    LuaPaintEvent()
                    {
                        x = 0;
                        y = 0;
                    }
                };

                std::function<void(int x, int y, int button)> luaFunction;
                bool needsCelCoordinates() const override { return false; }
                
                LuaInk();

                Ink *clone() override { return new LuaInk(*this); }
                void inkHline(int x1, int y, int x2, ToolLoop* loop) override;
                void prepareForPointShape(ToolLoop* loop, bool firstPoint, int x, int y) override;
                void prepareVForPointShape(ToolLoop* loop, int y) override;
                void prepareUForPointShapeWholeScanline(ToolLoop* loop, int x1) override;
                void prepareUForPointShapeSlicedScanline(ToolLoop* loop, bool leftSlice, int x1) override;

            private:
                LuaPaintEvent m_paintEvent;
                app::tools::ToolLoop* m_lastLoop;
        };
    }
}