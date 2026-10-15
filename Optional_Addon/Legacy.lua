--[[
    GlobalTools_Legacy - Sistema Legacy (mod-legacy) como addon INDIVIDUAL
    WoW 3.3.5a (AzerothCore con mod-legacy)

    Funciona de dos formas, sin cambiar nada:
      * Con el hub GlobalTools instalado: se integra solo (pestaña "Sistema Legacy",
        categoría en el menú desplegable y sincronización con /gt sync).
      * Sin el hub: abre su propia ventana con /glegacy.

    Todo lo de Legacy vive en este archivo: datos, lectura del chat, pestaña, menú y comandos.
    Árboles y nodos están en L.TREES (una sola tabla para pestaña y menú).
]]

local ADDON = "GlobalTools_Legacy"

GlobalToolsLegacy = GlobalToolsLegacy or {}
local L = GlobalToolsLegacy

-- ============================================================================
-- DATOS EN VIVO
-- ============================================================================
L.data = {
    points = 0,
    ranks = {
        [1] = { [1] = 0, [2] = 0, [3] = 0 }, -- Aventura
        [2] = { [1] = 0, [2] = 0, [3] = 0 }, -- Profesiones
        [3] = { [1] = 0, [2] = 0, [3] = 0 }, -- Recursos
    },
    loaded = false,
}
if GlobalTools then GlobalTools.LegacyData = L.data end -- compatibilidad con código antiguo

local ICON_MAIN = "Interface\\Icons\\Spell_Holy_ChampionsGrace"

-- ============================================================================
-- ÁRBOLES Y NODOS (cada nodo: .legacy buy <árbol> <nodo>)
-- ============================================================================
L.TREES = {
    {
        idx = 1, id = "tree_adventure",
        tabTitle = "|cff33ff33Árbol 1: Aventura|r",
        menuName = "Árbol: Aventura (Velocidad y XP)",
        menuDesc = "Mejoras de velocidad de movimiento y bonificación de experiencia.",
        icon = "Interface\\Icons\\Ability_Rogue_Sprint",
        nodes = {
            { id = "leg_adv_1", name = "Swift Boots", icon = "Interface\\Icons\\Ability_Rogue_Sprint",
              tabDesc = "+Velocidad de Movimiento pasiva.",
              menuName = "Swift Boots (+Velocidad de Mov.)",
              menuDesc = "Aumenta la velocidad de movimiento pasiva de tu personaje." },
            { id = "leg_adv_2", name = "Quick Study", icon = "Interface\\Icons\\Spell_Holy_BorrowedTime",
              tabDesc = "+XP de todas las fuentes de juego.",
              menuName = "Quick Study (+XP Global)",
              menuDesc = "Incrementa la experiencia obtenida de todas las fuentes." },
            { id = "leg_adv_3", name = "Wanderlust", icon = "Interface\\Icons\\Ability_Spy",
              tabDesc = "+XP adicional al explorar zonas.",
              menuName = "Wanderlust (+XP Exploración)",
              menuDesc = "Bonus de experiencia al descubrir nuevas zonas (se acumula con Quick Study)." },
        },
    },
    {
        idx = 2, id = "tree_professions",
        tabTitle = "|cff33ccffÁrbol 2: Profesiones|r",
        menuName = "Árbol: Profesiones (Subida y Crafteo)",
        menuDesc = "Mejoras para recolección y creación de objetos.",
        icon = "Interface\\Icons\\Trade_BlackSmithing",
        nodes = {
            { id = "leg_prof_1", name = "Steady Hands", icon = "Interface\\Icons\\INV_Pick_02",
              tabDesc = "+Probabilidad de subir skill en recolección.",
              menuName = "Steady Hands (+Skill Recolección)",
              menuDesc = "Aumenta la probabilidad de subir habilidad en Minería, Herboristería y Desuello." },
            { id = "leg_prof_2", name = "Master Crafter", icon = "Interface\\Icons\\Trade_BlackSmithing",
              tabDesc = "+Probabilidad de subir skill en crafteo.",
              menuName = "Master Crafter (+Skill Crafteo)",
              menuDesc = "Aumenta la probabilidad de subir nivel en profesiones de crafteo." },
            { id = "leg_prof_3", name = "Bountiful Harvest", icon = "Interface\\Icons\\Spell_Nature_NatureBlessing",
              tabDesc = "Nodo reservado en v1 (bloqueado).",
              menuName = "|cff808080Bountiful Harvest (Bloqueado)|r",
              menuDesc = "Nodo reservado para futuras actualizaciones del servidor.",
              locked = true },
        },
    },
    {
        idx = 3, id = "tree_resources",
        tabTitle = "|cffffd100Árbol 3: Recursos|r",
        menuName = "Árbol: Recursos (Oro y Descuentos)",
        menuDesc = "Más oro de criaturas y descuentos en vendedores y reparaciones.",
        icon = "Interface\\Icons\\INV_Misc_Coin_01",
        nodes = {
            { id = "leg_res_1", name = "Grave Robber", icon = "Interface\\Icons\\INV_Misc_Coin_01",
              tabDesc = "+Oro saqueado de criaturas y cofres.",
              menuName = "Grave Robber (+Oro de Botín)",
              menuDesc = "Aumenta la cantidad de monedas obtenidas de criaturas y cofres." },
            { id = "leg_res_2", name = "Haggler", icon = "Interface\\Icons\\INV_Misc_Bag_07_Black",
              tabDesc = "Descuento en compras a vendedores.",
              menuName = "Haggler (Descuento Vendedores)",
              menuDesc = "Descuento en compras a vendedores de facción." },
            { id = "leg_res_3", name = "Frugal Repairs", icon = "Interface\\Icons\\INV_Hammer_15",
              tabDesc = "Descuento adicional en reparación de equipo.",
              menuName = "Frugal Repairs (Descuento Reparación)",
              menuDesc = "Descuento adicional en el coste de reparar equipo." },
        },
    },
}

local function BuyCmd(tree, node) return ".legacy buy " .. tree.idx .. " " .. node end

-- ============================================================================
-- CONFIGURACIÓN PROPIA (SavedVariables: GlobalToolsLegacyDB)
-- ============================================================================
local function DB()
    GlobalToolsLegacyDB = GlobalToolsLegacyDB or {}
    if GlobalToolsLegacyDB.hideChat == nil then GlobalToolsLegacyDB.hideChat = true end
    return GlobalToolsLegacyDB
end

-- ¿Se oculta del chat lo que responde el servidor? Con el hub se usa su opción general.
function L:ShouldHide()
    if GlobalToolsDB and GlobalToolsDB.hideChatMessages ~= nil then
        return GlobalToolsDB.hideChatMessages
    end
    return DB().hideChat
end

-- ============================================================================
-- ENVÍO DE COMANDOS Y CONFIRMACIONES
-- ============================================================================
StaticPopupDialogs["GTLEGACY_CONFIRM"] = {
    text = "%s",
    button1 = "Aceptar",
    button2 = "Cancelar",
    OnAccept = function(self, data)
        if data then L:Send(data) end
    end,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
    preferredIndex = 3,
}

function L:Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ccff[Legacy]|r " .. tostring(msg))
end

function L:Send(cmd)
    if not cmd or cmd == "" then return end
    if UnitAffectingCombat("player") then
        UIErrorsFrame:AddMessage("|cffff2020[Legacy] Advertencia: Estás en combate.|r", 1.0, 0.2, 0.2, 1.0)
    end
    PlaySound("igMainMenuOptionCheckBoxOn")
    SendChatMessage(cmd, "SAY")
end

function L:Run(cmd, confirm)
    if confirm then
        local dialog = StaticPopup_Show("GTLEGACY_CONFIRM", confirm)
        if dialog then dialog.data = cmd end
    else
        L:Send(cmd)
    end
end

-- Pide al servidor los puntos y rangos (la respuesta la lee ProcessChat)
function L:Sync()
    SendChatMessage(".legacy", "SAY")
end

-- Tras una mejora o reembolso se vuelve a sincronizar, pero una sola vez
-- (el mismo mensaje puede llegar por el filtro y por el evento)
local lastTrigger = 0
local function TriggerSync()
    local now = GetTime()
    if now - lastTrigger < 0.5 then return end
    lastTrigger = now
    L:Sync()
end

-- ============================================================================
-- LECTURA DE LAS RESPUESTAS DEL SERVIDOR
-- Devuelve true si la línea es de Legacy (para poder ocultarla del chat)
-- ============================================================================
function L:ProcessChat(msg)
    if not msg then return false end
    local clean = msg:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")

    -- 1. Reembolso: "[Legacy] 3 point(s) refunded to the account pool."
    --    (va antes que "puntos disponibles": las dos empiezan igual y se confundían)
    if clean:match("%[Legacy%]%s*(%d+)%s*point%(s%) refunded") then
        for t = 1, 3 do
            for n = 1, 3 do L.data.ranks[t][n] = 0 end
        end
        L:Update()
        TriggerSync()
        return false
    end

    -- 2. Mejora exitosa: "[Legacy] Swift Boots raised to rank 2: +move speed."
    if clean:match("%[Legacy%]%s*(.-)%s*raised to rank%s*(%d+)") then
        TriggerSync()
        return false -- dejar ver el mensaje de felicitación
    end

    -- 3. Puntos disponibles: "[Legacy] 5 point(s) available"
    local pts = clean:match("%[Legacy%]%s*(%d+)%s*point")
    if pts then
        L.data.points = tonumber(pts)
        L.data.loaded = true
        L:Update()
        return true
    end

    -- 4. Rango de nodo: "  1.1 Swift Boots - +move speed (rank 1/3, next rank costs 2)"
    local tree, node, rank = clean:match("^%s*(%d+)%.(%d+)%s+.-%(rank%s+(%d+)/")
    if tree and node and rank then
        tree, node, rank = tonumber(tree), tonumber(node), tonumber(rank)
        if L.data.ranks[tree] then L.data.ranks[tree][node] = rank end
        L.data.loaded = true
        L:Update()
        return true
    end

    -- Encabezados y ayuda de legacy (se ocultan si el silencio está activado)
    if clean:find("^%-%- Adventure %-%-") or clean:find("^%-%- Professions %-%-")
        or clean:find("^%-%- Resourcefulness %-%-") or clean:find("Use '%.legacy buy") then
        return true
    end

    return false
end

ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", function(self, event, msg, ...)
    if L:ProcessChat(msg) and L:ShouldHide() then
        return true
    end
    return false, msg, ...
end)

-- ============================================================================
-- INTERFAZ: PANEL (sirve para la pestaña del hub y para la ventana propia)
-- ============================================================================
local ui = {}  -- referencias a los textos que se actualizan en vivo

local function CreateActionButton(parent, width, height, text, iconTexture, onClick)
    local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    btn:SetWidth(width or 130)
    btn:SetHeight(height or 28)
    btn:SetText(text or "Abrir")
    if iconTexture then
        local icon = btn:CreateTexture(nil, "OVERLAY")
        icon:SetWidth(height - 8)
        icon:SetHeight(height - 8)
        icon:SetPoint("LEFT", btn, "LEFT", 5, 0)
        icon:SetTexture(iconTexture)
        local fs = btn:GetFontString()
        if fs then
            fs:ClearAllPoints()
            fs:SetPoint("LEFT", icon, "RIGHT", 4, 0)
            fs:SetPoint("RIGHT", btn, "RIGHT", -4, 0)
        end
    end
    if onClick then
        btn:SetScript("OnClick", function(self)
            PlaySound("igMainMenuOptionCheckBoxOn")
            onClick(self)
        end)
    end
    return btn
end

function L:BuildPanel(p)
    ui.nodeRows = {}

    local headerCard = CreateFrame("Frame", nil, p)
    headerCard:SetWidth(536)
    headerCard:SetHeight(48)
    headerCard:SetPoint("TOPLEFT", p, "TOPLEFT", 12, -8)

    local cardBg = headerCard:CreateTexture(nil, "BACKGROUND")
    cardBg:SetAllPoints()
    cardBg:SetTexture(0.08, 0.22, 0.35, 0.6)

    local title = headerCard:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", headerCard, "TOPLEFT", 10, -8)
    title:SetText("Sistema Legacy")

    ui.points = headerCard:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    ui.points:SetPoint("BOTTOMLEFT", headerCard, "BOTTOMLEFT", 10, 8)
    ui.points:SetText("Puntos Disponibles: |cff00ff00Cargando...|r")

    local syncBtn = CreateActionButton(headerCard, 140, 26, "Sincronizar", ICON_MAIN, function() L:Sync() end)
    syncBtn:SetPoint("RIGHT", headerCard, "RIGHT", -8, 0)

    local y = -62
    for _, tree in ipairs(L.TREES) do
        local treeTitle = p:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        treeTitle:SetPoint("TOPLEFT", p, "TOPLEFT", 14, y)
        treeTitle:SetText(tree.tabTitle)
        y = y - 18

        for nodeIdx, n in ipairs(tree.nodes) do
            local row = CreateFrame("Frame", nil, p)
            row:SetWidth(536)
            row:SetHeight(32)
            row:SetPoint("TOPLEFT", p, "TOPLEFT", 12, y)

            local bg = row:CreateTexture(nil, "BACKGROUND")
            bg:SetAllPoints()
            bg:SetTexture(0.12, 0.12, 0.15, 0.35)

            local icon = row:CreateTexture(nil, "ARTWORK")
            icon:SetWidth(24)
            icon:SetHeight(24)
            icon:SetPoint("LEFT", row, "LEFT", 6, 0)
            icon:SetTexture(n.icon)
            icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

            local nameLabel = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            nameLabel:SetPoint("LEFT", icon, "RIGHT", 8, 0)
            nameLabel:SetText(n.name .. " |cff808080(" .. n.tabDesc .. ")|r")

            local badge = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            badge:SetPoint("RIGHT", row, "RIGHT", -95, 0)
            badge:SetText(n.locked and "|cff808080[Bloqueado]|r" or "|cffffd100Rango 0/3|r")

            ui.nodeRows[tree.idx .. "_" .. nodeIdx] = { badge = badge, locked = n.locked }

            if not n.locked then
                local buyBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
                buyBtn:SetWidth(85)
                buyBtn:SetHeight(22)
                buyBtn:SetPoint("RIGHT", row, "RIGHT", -6, 0)
                buyBtn:SetText("+1 Rango")
                local cmd, nodeName = BuyCmd(tree, nodeIdx), n.name
                buyBtn:SetScript("OnClick", function()
                    L:Run(cmd, "¿Gastar punto(s) Legacy en mejorar " .. nodeName .. "?")
                end)
            end

            y = y - 34
        end
        y = y - 4
    end

    local resetBtn = CreateActionButton(p, 250, 26, "Reiniciar Puntos Gastados",
        "Interface\\Icons\\Spell_Shadow_SacrificialShield", function()
            L:Run(".legacy reset", "¿Estás seguro de que deseas reiniciar todos los puntos Legacy?")
        end)
    resetBtn:SetPoint("BOTTOMLEFT", p, "BOTTOMLEFT", 14, 10)

    L:Update()
end

-- Refresca los textos con los datos actuales (si el panel aún no existe, no hace nada)
function L:Update()
    if ui.points then
        ui.points:SetText("Puntos Legacy de Cuenta Disponibles: |cff00ff00" .. (L.data.points or 0) .. " Punto(s)|r")
    end
    if not ui.nodeRows then return end
    for key, row in pairs(ui.nodeRows) do
        if row.badge and not row.locked then
            local t, n = key:match("(%d+)_(%d+)")
            local rank = (L.data.ranks[tonumber(t)] and L.data.ranks[tonumber(t)][tonumber(n)]) or 0
            if rank >= 3 then
                row.badge:SetText("|cff00ff00[Rango 3/3 MAX]|r")
            else
                row.badge:SetText("|cffffd100[Rango " .. rank .. "/3]|r |cff808080(Sig: " .. (rank + 1) .. " pt)|r")
            end
        end
    end
end

-- ============================================================================
-- MENÚ DESPLEGABLE DEL HUB (se genera desde L.TREES)
-- ============================================================================
function L:BuildMenuCategory()
    local items = {
        {
            id = "legacy_status", name = "Consultar Puntos Legacy",
            desc = "Muestra en el chat tus puntos disponibles y rangos actuales.",
            icon = ICON_MAIN, cmd = ".legacy", enabled = true,
        },
    }
    for _, tree in ipairs(L.TREES) do
        local subs = {}
        for nodeIdx, n in ipairs(tree.nodes) do
            if n.locked then
                subs[#subs + 1] = { id = n.id, name = n.menuName, desc = n.menuDesc, icon = n.icon,
                                    cmd = "", disabled = true, enabled = true }
            else
                subs[#subs + 1] = { id = n.id, name = n.menuName, desc = n.menuDesc, icon = n.icon,
                                    cmd = BuyCmd(tree, nodeIdx),
                                    confirm = "¿Gastar 1 punto Legacy en " .. n.name .. "?", enabled = true }
            end
        end
        items[#items + 1] = { id = tree.id, name = tree.menuName, desc = tree.menuDesc, icon = tree.icon,
                              hasSubmenu = true, enabled = true, subitems = subs }
    end
    items[#items + 1] = {
        id = "legacy_reset", name = "|cffff2020Reiniciar Puntos Legacy|r",
        desc = "Devuelve todos los puntos gastados por este personaje al pozo de la cuenta.",
        icon = "Interface\\Icons\\Spell_Shadow_SacrificialShield", cmd = ".legacy reset",
        confirm = "¿Estás seguro de que deseas reiniciar (Refund) todos los nodos Legacy de este personaje?",
        enabled = true,
    }
    return {
        id = "legacy", name = "Sistema Legacy", icon = ICON_MAIN,
        tooltip = "Progresión ligada a la cuenta. Gasta puntos Legacy en 3 árboles de ventajas.",
        enabled = true, order = 3, items = items,
    }
end

-- ============================================================================
-- VENTANA PROPIA (/glegacy) - sirve con o sin el hub
-- ============================================================================
function L:ToggleWindow()
    if not L.window then
        local f = CreateFrame("Frame", "GlobalToolsLegacyFrame", UIParent)
        f:SetWidth(580)
        f:SetHeight(520)
        f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        f:SetFrameStrata("HIGH")
        f:SetMovable(true)
        f:EnableMouse(true)
        f:SetClampedToScreen(true)
        f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", function(self) self:StartMoving() end)
        f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
        f:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 32,
            insets = { left = 11, right = 12, top = 12, bottom = 11 },
        })

        local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOP", f, "TOP", 0, -14)
        title:SetText("|cff00ccffGlobalTools|r Legacy")

        local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
        close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -6, -6)

        local content = CreateFrame("Frame", nil, f)
        content:SetWidth(560)
        content:SetHeight(465)
        content:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -40)
        L:BuildPanel(content)

        tinsert(UISpecialFrames, "GlobalToolsLegacyFrame")
        L.window = f
        f:Hide()
    end

    if L.window:IsShown() then
        L.window:Hide()
    else
        L.window:Show()
        L:Sync()
    end
end

SLASH_GLOBALTOOLSLEGACY1 = "/glegacy"
SlashCmdList["GLOBALTOOLSLEGACY"] = function(msg)
    msg = msg and msg:lower():match("^%s*(.-)%s*$") or ""
    if msg == "sync" then
        L:Sync()
        L:Print("Sincronizando puntos Legacy...")
    elseif msg == "chat" then
        local db = DB()
        db.hideChat = not db.hideChat
        L:Print("Ocultar respuestas del chat: " .. (db.hideChat and "|cff00ff00sí|r" or "|cffff2020no|r"))
    elseif msg == "help" or msg == "?" then
        L:Print("Comandos: |cffffd100/glegacy|r abre la ventana, |cffffd100/glegacy sync|r sincroniza, |cffffd100/glegacy chat|r oculta/muestra las respuestas del chat.")
    else
        L:ToggleWindow()
    end
end

-- ============================================================================
-- EVENTOS (también lee el chat por evento: el filtro solo corre si el mensaje se muestra)
-- ============================================================================
local ev = CreateFrame("Frame")
ev:RegisterEvent("ADDON_LOADED")
ev:RegisterEvent("CHAT_MSG_SYSTEM")
ev:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == ADDON then
        DB()
    elseif event == "CHAT_MSG_SYSTEM" then
        L:ProcessChat(arg1)
    end
end)

-- ============================================================================
-- REGISTRO EN EL HUB (si está instalado)
-- ============================================================================
local GT = GlobalTools
if GT and GT.RegisterModule then
    GT:RegisterModule({
        id = "legacy",
        name = "Sistema Legacy",
        icon = ICON_MAIN,
        slot = 3, -- posición de la pestaña en la barra lateral del hub
        tab = {
            build = function(parent) L:BuildPanel(parent) end,
            onSelect = function() L:Sync() end,
            onUpdate = function() L:Update() end,
        },
        category = L:BuildMenuCategory(),
        sync = function() L:Sync() end,
        help = { "|cffffd100/glegacy|r - Abre la ventana propia de Legacy" },
    })
end
