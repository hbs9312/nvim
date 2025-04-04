-- plugins/cmp.lua
return {
  "hrsh7th/nvim-cmp",
  event = "InsertEnter",
  dependencies = {
    "hrsh7th/cmp-nvim-lsp",       -- LSP 자동완성
    "hrsh7th/cmp-buffer",         -- 버퍼 내용 자동완성
    "hrsh7th/cmp-path",           -- 경로 자동완성
    "hrsh7th/cmp-cmdline",        -- 커맨드라인 자동완성
    "saadparwaiz1/cmp_luasnip",   -- LuaSnip 연동
    "L3MON4D3/LuaSnip",           -- 스니펫 엔진
    "rafamadriz/friendly-snippets", -- 자주 쓰이는 스니펫 모음
  },
  config = function()
    local cmp = require("cmp")
    local luasnip = require("luasnip")

    require("luasnip.loaders.from_vscode").lazy_load() -- friendly-snippets 로딩

    cmp.setup({
      snippet = {
        expand = function(args)
          luasnip.lsp_expand(args.body) -- LuaSnip 사용
        end,
      },
      mapping = cmp.mapping.preset.insert({
        ["<Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_next_item()
          elseif luasnip.expand_or_jumpable() then
            luasnip.expand_or_jump()
          else
            fallback()
          end
        end, { "i", "s" }),

        ["<S-Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_prev_item()
          elseif luasnip.jumpable(-1) then
            luasnip.jump(-1)
          else
            fallback()
          end
        end, { "i", "s" }),

        ["<CR>"] = cmp.mapping.confirm({ select = true }),
        ["<C-Space>"] = cmp.mapping.complete(),
      }),
      sources = cmp.config.sources({
        { name = "nvim_lsp" },
        { name = "luasnip" },
        { name = "buffer" },
        { name = "path" },
      }),
    })
  end,
}

