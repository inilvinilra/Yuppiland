-- ╔══════════════════════════════════════════════════════════════╗
-- ║  VOID — Neovim Colorscheme                                  ║
-- ║  ~/.config/nvim/colors/void.lua                              ║
-- ╚══════════════════════════════════════════════════════════════╝

vim.cmd("hi clear")
if vim.fn.exists("syntax_on") then
    vim.cmd("syntax reset")
end
vim.g.colors_name = "void"
vim.o.termguicolors = true
vim.o.background = "dark"

-- ── VOID PALETTE ──
local p = {
    bg       = "#000000",
    surface  = "#080808",
    overlay  = "#1a1a1a",
    muted    = "#2a2a2a",
    subtle   = "#555555",
    subtext  = "#888888",
    text     = "#cccccc",
    bright   = "#e8e8e8",
    white    = "#ffffff",
    red      = "#cc4444",
    yellow   = "#c8a84b",
    green    = "#5a8a5a",
    none     = "NONE",
}

local function hi(group, opts)
    vim.api.nvim_set_hl(0, group, opts)
end

-- ── EDITOR ──
hi("Normal",           { fg = p.text,    bg = p.bg })
hi("NormalFloat",      { fg = p.text,    bg = p.surface })
hi("FloatBorder",      { fg = p.overlay, bg = p.surface })
hi("FloatTitle",       { fg = p.bright,  bg = p.surface, bold = true })
hi("Cursor",           { fg = p.bg,      bg = p.text })
hi("CursorLine",       { bg = p.surface })
hi("CursorLineNr",     { fg = p.subtext, bg = p.surface })
hi("LineNr",           { fg = p.muted })
hi("SignColumn",       { fg = p.muted,   bg = p.bg })
hi("ColorColumn",      { bg = p.surface })
hi("Visual",           { bg = p.overlay })
hi("VisualNOS",        { bg = p.overlay })
hi("Search",           { fg = p.bg,      bg = p.subtext })
hi("IncSearch",        { fg = p.bg,      bg = p.bright })
hi("CurSearch",        { fg = p.bg,      bg = p.bright })
hi("Substitute",       { fg = p.bg,      bg = p.yellow })
hi("MatchParen",       { fg = p.bright,  bg = p.overlay, bold = true })
hi("Folded",           { fg = p.subtle,  bg = p.surface })
hi("FoldColumn",       { fg = p.muted,   bg = p.bg })
hi("VertSplit",        { fg = p.overlay })
hi("WinSeparator",     { fg = p.overlay })
hi("StatusLine",       { fg = p.text,    bg = p.surface })
hi("StatusLineNC",     { fg = p.subtle,  bg = p.surface })
hi("TabLine",          { fg = p.subtle,  bg = p.surface })
hi("TabLineSel",       { fg = p.bright,  bg = p.overlay })
hi("TabLineFill",      { bg = p.bg })
hi("WinBar",           { fg = p.text,    bg = p.bg, bold = true })
hi("WinBarNC",         { fg = p.subtle,  bg = p.bg })
hi("Title",            { fg = p.bright,  bold = true })
hi("NonText",          { fg = p.muted })
hi("Whitespace",       { fg = p.muted })
hi("SpecialKey",       { fg = p.muted })
hi("Conceal",          { fg = p.subtle })
hi("EndOfBuffer",      { fg = p.bg })
hi("Directory",        { fg = p.text })
hi("Question",         { fg = p.subtext })
hi("MoreMsg",          { fg = p.subtext })
hi("ModeMsg",          { fg = p.subtext })
hi("WarningMsg",       { fg = p.yellow })
hi("ErrorMsg",         { fg = p.red,     bold = true })
hi("Error",            { fg = p.red })

-- ── PMENU (completion) ──
hi("Pmenu",            { fg = p.text,    bg = p.surface })
hi("PmenuSel",         { fg = p.bright,  bg = p.overlay })
hi("PmenuSbar",        { bg = p.surface })
hi("PmenuThumb",       { bg = p.muted })

-- ── SYNTAX ──
hi("Comment",          { fg = p.subtle,  italic = true })
hi("Constant",         { fg = p.subtext })
hi("String",           { fg = p.subtext })
hi("Character",        { fg = p.subtext })
hi("Number",           { fg = p.text })
hi("Boolean",          { fg = p.text })
hi("Float",            { fg = p.text })
hi("Identifier",       { fg = p.text })
hi("Function",         { fg = p.bright })
hi("Statement",        { fg = p.text })
hi("Conditional",      { fg = p.text,    bold = true })
hi("Repeat",           { fg = p.text,    bold = true })
hi("Label",            { fg = p.subtext })
hi("Operator",         { fg = p.subtle })
hi("Keyword",          { fg = p.text,    bold = true })
hi("Exception",        { fg = p.text,    bold = true })
hi("PreProc",          { fg = p.subtext })
hi("Include",          { fg = p.subtext })
hi("Define",           { fg = p.subtext })
hi("Macro",            { fg = p.subtext })
hi("PreCondit",        { fg = p.subtext })
hi("Type",             { fg = p.text })
hi("StorageClass",     { fg = p.text,    bold = true })
hi("Structure",        { fg = p.text })
hi("Typedef",          { fg = p.text })
hi("Special",          { fg = p.subtext })
hi("SpecialChar",      { fg = p.subtext })
hi("Tag",              { fg = p.text })
hi("Delimiter",        { fg = p.subtle })
hi("SpecialComment",   { fg = p.subtle,  italic = true })
hi("Debug",            { fg = p.subtle })
hi("Underlined",       { fg = p.text,    underline = true })
hi("Ignore",           { fg = p.muted })
hi("Todo",             { fg = p.bg,      bg = p.subtext, bold = true })

-- ── DIFF ──
hi("DiffAdd",          { fg = p.green,   bg = p.bg })
hi("DiffChange",       { fg = p.yellow,  bg = p.bg })
hi("DiffDelete",       { fg = p.red,     bg = p.bg })
hi("DiffText",         { fg = p.yellow,  bg = p.surface, bold = true })
hi("Added",            { fg = p.green })
hi("Changed",          { fg = p.yellow })
hi("Removed",          { fg = p.red })

-- ── DIAGNOSTICS ──
hi("DiagnosticError",            { fg = p.red })
hi("DiagnosticWarn",             { fg = p.yellow })
hi("DiagnosticInfo",             { fg = p.subtext })
hi("DiagnosticHint",             { fg = p.subtle })
hi("DiagnosticOk",               { fg = p.green })
hi("DiagnosticUnderlineError",   { sp = p.red,    undercurl = true })
hi("DiagnosticUnderlineWarn",    { sp = p.yellow, undercurl = true })
hi("DiagnosticUnderlineInfo",    { sp = p.subtext, underline = true })
hi("DiagnosticUnderlineHint",    { sp = p.subtle, underline = true })
hi("DiagnosticVirtualTextError", { fg = p.red,    bg = p.surface })
hi("DiagnosticVirtualTextWarn",  { fg = p.yellow, bg = p.surface })
hi("DiagnosticVirtualTextInfo",  { fg = p.subtext, bg = p.surface })
hi("DiagnosticVirtualTextHint",  { fg = p.subtle, bg = p.surface })
hi("DiagnosticSignError",        { fg = p.red,    bg = p.bg })
hi("DiagnosticSignWarn",         { fg = p.yellow, bg = p.bg })
hi("DiagnosticSignInfo",         { fg = p.subtext, bg = p.bg })
hi("DiagnosticSignHint",         { fg = p.subtle, bg = p.bg })

-- ── GIT SIGNS ──
hi("GitSignsAdd",      { fg = p.green })
hi("GitSignsChange",   { fg = p.yellow })
hi("GitSignsDelete",   { fg = p.red })

-- ── TREESITTER ──
hi("@comment",                { link = "Comment" })
hi("@constant",               { fg = p.text })
hi("@constant.builtin",       { fg = p.subtext })
hi("@constant.macro",         { fg = p.subtext })
hi("@string",                 { fg = p.subtext })
hi("@string.escape",          { fg = p.subtle })
hi("@string.special",         { fg = p.subtle })
hi("@character",              { fg = p.subtext })
hi("@number",                 { fg = p.text })
hi("@boolean",                { fg = p.text })
hi("@float",                  { fg = p.text })
hi("@function",               { fg = p.bright })
hi("@function.builtin",       { fg = p.text })
hi("@function.macro",         { fg = p.subtext })
hi("@function.call",          { fg = p.text })
hi("@method",                 { fg = p.bright })
hi("@method.call",            { fg = p.text })
hi("@constructor",            { fg = p.text })
hi("@parameter",              { fg = p.text, italic = true })
hi("@keyword",                { fg = p.text, bold = true })
hi("@keyword.function",       { fg = p.text, bold = true })
hi("@keyword.operator",       { fg = p.subtle })
hi("@keyword.return",         { fg = p.text, bold = true })
hi("@conditional",            { fg = p.text, bold = true })
hi("@repeat",                 { fg = p.text, bold = true })
hi("@label",                  { fg = p.subtext })
hi("@operator",               { fg = p.subtle })
hi("@exception",              { fg = p.text, bold = true })
hi("@variable",               { fg = p.text })
hi("@variable.builtin",       { fg = p.subtext, italic = true })
hi("@type",                   { fg = p.text })
hi("@type.builtin",           { fg = p.subtext })
hi("@type.qualifier",         { fg = p.text, bold = true })
hi("@include",                { fg = p.subtext })
hi("@namespace",              { fg = p.text })
hi("@field",                  { fg = p.text })
hi("@property",               { fg = p.text })
hi("@punctuation.bracket",    { fg = p.subtle })
hi("@punctuation.delimiter",  { fg = p.subtle })
hi("@punctuation.special",    { fg = p.subtle })
hi("@tag",                    { fg = p.text })
hi("@tag.attribute",          { fg = p.subtext, italic = true })
hi("@tag.delimiter",          { fg = p.subtle })
hi("@text",                   { fg = p.text })
hi("@text.strong",            { fg = p.bright, bold = true })
hi("@text.emphasis",          { fg = p.text, italic = true })
hi("@text.underline",         { fg = p.text, underline = true })
hi("@text.strike",            { fg = p.subtle, strikethrough = true })
hi("@text.title",             { fg = p.bright, bold = true })
hi("@text.uri",               { fg = p.subtext, underline = true })
hi("@text.todo",              { link = "Todo" })
hi("@text.note",              { fg = p.subtext, bg = p.surface })

-- ── TELESCOPE ──
hi("TelescopeNormal",         { fg = p.text,    bg = p.bg })
hi("TelescopeBorder",         { fg = p.overlay, bg = p.bg })
hi("TelescopePromptNormal",   { fg = p.text,    bg = p.surface })
hi("TelescopePromptBorder",   { fg = p.overlay, bg = p.surface })
hi("TelescopePromptPrefix",   { fg = p.subtle })
hi("TelescopePromptTitle",    { fg = p.bright,  bg = p.surface })
hi("TelescopeResultsNormal",  { fg = p.text,    bg = p.bg })
hi("TelescopeResultsBorder",  { fg = p.overlay, bg = p.bg })
hi("TelescopeResultsTitle",   { fg = p.subtext })
hi("TelescopePreviewNormal",  { fg = p.text,    bg = p.bg })
hi("TelescopePreviewBorder",  { fg = p.overlay, bg = p.bg })
hi("TelescopePreviewTitle",   { fg = p.subtext })
hi("TelescopeSelection",      { fg = p.bright,  bg = p.overlay })
hi("TelescopeSelectionCaret",  { fg = p.bright })
hi("TelescopeMatching",       { fg = p.bright,  bold = true })

-- ── LAZY / MASON ──
hi("LazyNormal",      { fg = p.text,    bg = p.surface })
hi("LazyButton",      { fg = p.text,    bg = p.overlay })
hi("LazyButtonActive", { fg = p.bright, bg = p.muted })
hi("LazyH1",          { fg = p.bright,  bold = true })
hi("MasonNormal",     { fg = p.text,    bg = p.surface })
hi("MasonHeader",     { fg = p.bright,  bg = p.overlay, bold = true })

-- ── INDENT BLANKLINE ──
hi("IblIndent",       { fg = p.surface })
hi("IblScope",        { fg = p.muted })

-- ── WHICH-KEY ──
hi("WhichKey",        { fg = p.bright })
hi("WhichKeyGroup",   { fg = p.subtext })
hi("WhichKeyDesc",    { fg = p.text })
hi("WhichKeySeparator", { fg = p.muted })
hi("WhichKeyFloat",   { bg = p.surface })

-- ── NOTIFY ──
hi("NotifyBackground", { bg = p.surface })
hi("NotifyERRORBody",  { fg = p.text })
hi("NotifyWARNBody",   { fg = p.text })
hi("NotifyINFOBody",   { fg = p.text })
hi("NotifyERRORTitle", { fg = p.red })
hi("NotifyWARNTitle",  { fg = p.yellow })
hi("NotifyINFOTitle",  { fg = p.subtext })
hi("NotifyERRORBorder", { fg = p.red })
hi("NotifyWARNBorder",  { fg = p.yellow })
hi("NotifyINFOBorder",  { fg = p.overlay })

-- ── CMP ──
hi("CmpItemAbbr",           { fg = p.text })
hi("CmpItemAbbrMatch",      { fg = p.bright, bold = true })
hi("CmpItemAbbrMatchFuzzy", { fg = p.bright })
hi("CmpItemAbbrDeprecated", { fg = p.subtle, strikethrough = true })
hi("CmpItemKind",           { fg = p.subtext })
hi("CmpItemMenu",           { fg = p.subtle })

-- ── MINI ──
hi("MiniStatuslineFilename",   { fg = p.text,    bg = p.surface })
hi("MiniStatuslineDevinfo",    { fg = p.subtext, bg = p.surface })
hi("MiniStatuslineFileinfo",   { fg = p.subtext, bg = p.surface })
hi("MiniStatuslineModeNormal", { fg = p.bg,      bg = p.subtext, bold = true })
hi("MiniStatuslineModeInsert", { fg = p.bg,      bg = p.text, bold = true })
hi("MiniStatuslineModeVisual", { fg = p.bg,      bg = p.subtle, bold = true })
hi("MiniStatuslineModeCommand",{ fg = p.bg,      bg = p.subtext, bold = true })
